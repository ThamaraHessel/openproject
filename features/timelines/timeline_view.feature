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

Feature: Timeline View Tests
	As a Project Member
	I want to view the timeline data
	change the timeline selection
	edit planning elements via a modal window

  Background:
    Given there are the following planning element types:
          | Name      | Is Milestone | In aggregation |
          | Phase     | false        | true           |
          | Milestone | true         | true           |

      And there are the following project types:
          | Name                  |
          | Standard Project      |
          | Extraordinary Project |

      And the following planning element types are default for projects of type "Standard Project"
          | Phase     |
          | Milestone |

      And there is 1 user with:
          | login | manager |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines           |
          | edit_timelines           |
          | view_planning_elements   |
          | move_planning_elements_to_trash  |
          | delete_planning_elements  |
          | edit_planning_elements   |
          | delete_planning_elements |

      And there is a project named "ecookbook" of type "Standard Project"
      And I am working in project "ecookbook"

      And the project uses the following modules:
          | timelines |

      And the user "manager" is a "manager"

      And I am logged in as "manager"

      And there are the following planning elements:
              | Subject  | Start date | Due date   | description       | status_name    | responsible    |
              | January  | 2012-01-01 | 2012-01-31 | Aioli Grande      | closed         | manager        |
              | February | 2012-02-01 | 2012-02-24 | Aioli Sali        | closed         | manager        |
              | March    | 2012-03-01 | 2012-03-30 | Sali Grande       | closed         | manager        |
              | April    | 2012-04-01 | 2012-04-30 | Aioli Sali Grande | closed         | manager        |
              | IchBinEinSoLangesPlannungselementIchMacheAllehierkRanKundDaNnaUcHnOcHdieseGroßUNDKleinSchReiBungWieklEiNeKinDer    | 2012-04-01 | 2012-04-30 | Devilish | closed         | manager        |

  Scenario: The project manager gets 'No data to display' when there are no planning elements defined
     When I go to the   page of the project called "ecookbook"
      And I toggle the "Timelines" submenu
      And I follow "Timeline reports"
     Then I should see "New timeline report"
     And I should see "General Settings"

  Scenario: create a timeline
    When there is a timeline "Testline" for project "ecookbook"
      And I go to the page of the project called "ecookbook"
      And I toggle the "Timelines" submenu
      And I follow "Timeline reports"
     Then I should see "New timeline report"
      And I should see "Testline"
      And I should be on the page of the timeline "Testline" of the project called "ecookbook"

   @javascript
  Scenario: planning element click should show modal window
    When there is a timeline "Testline" for project "ecookbook"
      And I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table
      And I click on the Planning Element with name "January"
     Then I should see a modal window
      And I should see "#1: January" in the modal
      And I should see "Aioli Grande" in the modal
      And I should see "01/01/2012" in the modal
      And I should see "01/31/2012" in the modal
      And I should see "New timeline report"
      And I should be on the page of the timeline "Testline" of the project called "ecookbook"

  @javascript
  Scenario: name column width
     When there is a timeline "Testline" for project "ecookbook"
      And I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table

     Then the first table column should not take more than 25% of the space