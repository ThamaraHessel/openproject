#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class Journal < ActiveRecord::Base
  self.table_name = "journals"

  include JournalFormatter
  include FormatHooks

  register_journal_formatter :diff, OpenProject::JournalFormatter::Diff
  register_journal_formatter :attachment, OpenProject::JournalFormatter::Attachment
  register_journal_formatter :custom_field, OpenProject::JournalFormatter::CustomField

  attr_accessible :journable_type, :journable_id, :activity_type, :version, :notes, :user_id

  # Make sure each journaled model instance only has unique version ids
  validates_uniqueness_of :version, :scope => [:journable_id, :journable_type]

  belongs_to :user
  belongs_to :journable, polymorphic: true

  has_many :attachable_journals, class_name: Journal::AttachableJournal, dependent: :destroy
  has_many :customizable_journals, class_name: Journal::CustomizableJournal, dependent: :destroy

  after_save :save_data, :touch_journable

  # Scopes to all journals excluding the initial journal - useful for change
  # logs like the history on issue#show
  scope "changing", :conditions => ["version > 1"]

  def changed_data=(changed_attributes)
    attributes = changed_attributes

    if attributes.kind_of? Hash and attributes.values.first.kind_of? Array
      attributes.each {|k,v| attributes[k] = v[1]}
    end

    data.update_attributes attributes
  end

  # In conjunction with the included Comparable module, allows comparison of journal records
  # based on their corresponding version numbers, creation timestamps and IDs.
  def <=>(other)
    [version, created_at, id].map(&:to_i) <=> [other.version, other.created_at, other.id].map(&:to_i)
  end

  # Returns whether the version has a version number of 1. Useful when deciding whether to ignore
  # the version during reversion, as initial versions have no serialized changes attached. Helps
  # maintain backwards compatibility.
  def initial?
    version < 2
  end

  # The anchor number for html output
  def anchor
    version - 1
  end

  # Possible shortcut to the associated project
  def project
    if journable.respond_to?(:project)
      journable.project
    elsif journable.is_a? Project
      journable
    else
      nil
    end
  end

  def editable_by?(user)
    journable.journal_editable_by?(user)
  end

  def details
    get_changes
  end

  alias_method :changed_data, :details

  def new_value_for(prop)
    details[prop.to_sym].last if details.keys.include? prop.to_sym
  end

  def old_value_for(prop)
    details[prop.to_sym].first if details.keys.include? prop.to_sym
  end

  def data
    @data ||= "Journal::#{journable_type}Journal".constantize.find_by_journal_id(id)
  end

  def data=(data)
    @data = data
  end

  def previous
    predecessor
  end

  private

  def save_data
    data.journal_id = id if data.new_record?
    data.save!
  end

  def touch_journable
    journable.touch unless journable.nil?
  end

  def get_changes
    return {} if data.nil?

    if @changes.nil?
      @changes = {}

      if predecessor.nil?
        @changes = data.journaled_attributes.select{|_,v| !v.nil?}
                                            .inject({}) { |h, (k, v)| h[k] = [nil, v]; h }
      else
        predecessor_data = predecessor.data.journaled_attributes
        data.journaled_attributes.select{|k,v| v != predecessor_data[k]}.each do |k, v|
          @changes[k] = [predecessor_data[k], v]
        end
      end

      @changes.merge!(get_association_changes predecessor, "attachable", "attachments", :attachment_id, :filename)
      @changes.merge!(get_association_changes predecessor, "customizable", "custom_fields", :custom_field_id, :value)
    end

    @changes
  end

  def get_association_changes(predecessor, journal_association, association, key, value)
    changes = {}
    journal_assoc_name = "#{journal_association}_journals".to_sym

    if predecessor.nil?
      send(journal_assoc_name).each_with_object(changes) {|a, h| h["#{association}_#{a.send(key)}".to_sym] = [nil, a.send(value)] }
    else
      current = send(journal_assoc_name).map(&:attributes)
      predecessor_attachable_journals = predecessor.send(journal_assoc_name).map(&:attributes)

      merged_journals = JournalManager.merge_reference_journals_by_id current,
                                                                      predecessor_attachable_journals,
                                                                      key.to_s

      changes.merge! JournalManager.added_references(merged_journals, association, value.to_s)
      changes.merge! JournalManager.removed_references(merged_journals, association, value.to_s)
      changes.merge! JournalManager.changed_references(merged_journals, association, value.to_s)
    end

    changes
  end

  def predecessor
    @predecessor ||= Journal.where("journable_type = ? AND journable_id = ? AND id < ?",
                                   journable_type, journable_id, id)
                            .order("version DESC")
                            .first
  end

  def journalized_object_type
    "#{journaled_type.gsub('Journal', '')}".constantize
  end
end
