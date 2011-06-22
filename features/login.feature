Feature: Authentication
	As a person interested in QA results
	I want to be able to login to QA-Dashboard
	So that I can personalize my dashboard

	Background:
		Given I have a browser session open

	Scenario: Log in with correct username and password
		Given I am on the front page
		And I am not logged in

		When I login with username "guest" and password "guest"

		Then I should be logged in
		And I should see "guest" as logged user


