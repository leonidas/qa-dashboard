Feature: Basic login and authentication
	As a person interested in QA results
	I want to be able to login to QA-Dashboard
	So that I can personalize my dashboard

	Background:
		Given I have a browser session open
		And I am on the front page
		And I am not logged in

	Scenario: Log in with correct username and password
		When I login with username "guest" and password "guest"

		Then I should be logged in
		And I should see "guest" as logged user

	Scenario: Log in with incorrect username and password
		When I login with username "unknownuser" and password "unknownpasswd"

		Then I should not be logged in
		And I should see login error "Invalid username or password"
