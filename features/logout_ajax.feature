Feature: Doing Ajax when logged out
  Background:
      And there is 1 user with:
          | login | manager |

      And there are the following project types:
          | Name                  |
          | Standard Project      |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_work_packages    |

      And there is a project named "ecookbook" of type "Standard Project"
      And I am working in project "ecookbook"

      And the user "manager" is a "manager"

      And I am logged in as "manager"

  @javascript
  Scenario: If we do ajax while being logged out a confirm dialog should open
    When I go to the issue page of the Project "ecookbook"
      And I log out in the background
      And I do some ajax
      And I confirm popups
    Then I should be on the login page
