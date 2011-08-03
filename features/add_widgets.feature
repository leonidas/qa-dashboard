Feature: Basic widgets functionality
	As a person interested in QA results
	I want to be able to add remove and move the widgets in my dashboard
	So that I can fit the data I need to view into my dashboard

	Background:
		Given I am on the front page
		And I am logged in

	Scenario: Add "Pass Rates Summary" widget to left column
		When I open the widget menu
		And I drag-n-drop a new "Pass Rates Summary" widget to the "left column"

		Then I should see a "widget_pass_rate" widget in the "left column"

	Scenario: Add "Pass Rates Summary" widget to sidebar
		When I open the widget menu
		And I drag-n-drop a new "Pass Rates Summary" widget to the "sidebar"

		Then I should see a "widget_pass_rate" widget in the "sidebar"

	Scenario: Add "Pass Rates Bar Chart" widget to left column
		When I open the widget menu
		And I drag-n-drop a new "Pass Rates Bar Chart" widget to the "left column"

		Then I should see a "widget_pass_rate_bars" widget in the "left column"

	Scenario: Add "Pass Rates Bar Chart" widget to sidebar
		When I open the widget menu
		And I drag-n-drop a new "Pass Rates Bar Chart" widget to the "sidebar"

		Then I should see a "widget_pass_rate_bars" widget in the "sidebar"

	Scenario: Add "Pass Rates Trend" widget to left column
		When I open the widget menu
		And I drag-n-drop a new "Pass Rates Trend" widget to the "left column"

		Then I should see a "widget_pass_rate_trend" widget in the "left column"

	Scenario: Add "Pass Rates Trend" widget to sidebar
		When I open the widget menu
		And I drag-n-drop a new "Pass Rates Trend" widget to the "sidebar"

		Then I should see a "widget_pass_rate_trend" widget in the "sidebar"

	Scenario: Add "Top Blocker Bugs" widget to left column
		When I open the widget menu
		And I drag-n-drop a new "Top Blocker Bugs" widget to the "left column"

		Then I should see a "widget_top_blockers" widget in the "left column"

	Scenario: Add "Top Blocker Bugs" widget to sidebar
		When I open the widget menu
		And I drag-n-drop a new "Top Blocker Bugs" widget to the "sidebar"

		Then I should see a "widget_top_blockers" widget in the "sidebar"
