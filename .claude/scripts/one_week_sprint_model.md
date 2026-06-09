# One Week Sprint Model for UCSC ITS Software Engineering Web Applications

## Purpose

This document describes how a one week sprint operates for a web software application supported by the UC Santa Cruz Information Technology Services Software Engineering Team.

The purpose of the one week sprint model is to provide a focused, time limited development cycle for a defined set of application changes. This model is intended for work that has already been reviewed, prioritized, clarified, and prepared before the sprint begins.

A one week sprint is most effective when the work is well understood, the scope is stable, and both the Software Engineering Team and client stakeholders are available for timely review and testing.

## Core Principles

The one week sprint model is based on the following principles:

- Sprint scope is defined before the sprint begins.
- All sprint work is tracked in Jira.
- The sprint board in the Jira project is the primary tool for managing sprint progress.
- Sprint goals are defined during sprint planning.
- Team member availability is considered before work is committed to the sprint.
- Sprint scope remains stable while the sprint is running.
- New issues are not added to the active sprint once it has started.
- Completed work is merged into the develop branch during the sprint.
- Each completed change is made available for testing in the AWS development tier.
- Integration testing occurs after individual changes have been brought together in the AWS stage environment.
- Release readiness is evaluated at the end of the sprint.
- After release, support transitions back to normal operational support processes.

## Definition of Ready

In a one week sprint, unclear requirements can consume an entire day of the available development window. To prevent this, a Jira issue cannot be pulled into the sprint unless it meets the following Definition of Ready (DoR) criteria:

- Fully documented acceptance criteria in the Jira issue
- UX/UI mockups or design references approved by the stakeholder, if applicable
- A technical approach or architecture review completed prior to the sprint
- A concrete size estimate. No single issue should exceed two days of effort in a one week sprint. Larger items must be decomposed before they can enter the sprint. For teams using story points with a standard Fibonacci sequence, no single issue accepted into the sprint should be estimated higher than 3 points. Issues estimated at 5 points or higher typically represent a week or more of complex effort and must be decomposed before entering the sprint.
- All external dependencies or blockers identified and resolved

Issues that do not meet the Definition of Ready should remain in the backlog until they are fully prepared. The sprint planning meeting is not the place to refine requirements.

## Continuous Integration and Continuous Inspection

A key feature of the one week sprint model is continuous integration and continuous inspection.

As each feature, fix, or technical task is completed, reviewed, and merged into the develop branch, the application becomes available for evaluation in the AWS development environment. This allows the client and the Software Engineering Team to inspect each change while the sprint is still in progress.

This approach helps reduce the risk of discovering all issues at the end of the sprint. Instead of waiting until final integration testing to evaluate completed work, individual changes can be reviewed as they become available.

The AWS development tier is used for early inspection of specific completed changes. The AWS stage tier is used for integration testing, where all completed changes are evaluated together as a release candidate.

### Automated Compliance Checks

As a UC Santa Cruz public university application, automated compliance checks must be integrated into the continuous integration pipeline. Upon merging to the develop branch, the following automated scans should run automatically:

- Accessibility scanning (e.g., Axe Core) to verify UC Web Accessibility compliance (WCAG 2.1/2.2 AA)
- Security vulnerability scanning (e.g., SonarQube, Snyk) for dependency and code-level issues
- Static analysis and linting for code quality standards

These scans should not be deferred to manual Thursday testing. Catching compliance issues at merge time prevents last-minute blockers during integration testing.

### Definition of Done (DoD)

To complement the Definition of Ready, a Definition of Done gate applies to all completed work. A Jira issue cannot be moved to "Ready for Stage Testing" unless it passes the CI pipeline with zero critical or high security vulnerabilities (Snyk/SonarQube) and zero violations of the UC Web Accessibility policy (Axe Core, WCAG 2.1/2.2 AA). Failing automated scans automatically rejects the pull request. This ensures that compliance issues are resolved at the feature level before they reach the integration testing window, rather than becoming Thursday blockers.

## Stable Sprint Scope

A second key feature of the one week sprint model is stable sprint scope.

Once the sprint begins, the scope should not change. New issues should not be added to the active sprint unless there is an exceptional production emergency requiring leadership review and explicit reprioritization.

Stable scope is important because a one week sprint has limited capacity. Adding new work during the sprint can disrupt development, testing, release readiness, and the ability to meet the sprint goals.

New requests, non urgent fixes, and enhancement ideas should be added to the Jira backlog for review and prioritization in a future sprint or planning cycle.

## Sprint Roles and Responsibilities

### Software Engineering Team

The Software Engineering Team is responsible for:

- Reviewing sprint readiness before the sprint begins
- Confirming that Jira issues are clear and actionable
- Developing, reviewing, merging, and testing code changes
- Maintaining the sprint board in Jira
- Deploying completed work to AWS development and stage environments
- Supporting integration testing
- Addressing issues identified during testing
- Preparing for release when the sprint is ready

### Product Owner / Client Stakeholders

Product Owner / Client Stakeholders are responsible for:

- Participating in sprint planning and sprint goal definition
- Confirming priorities before the sprint begins
- Reviewing completed changes during the sprint when they become available
- Participating in integration testing
- Confirming whether completed work meets the intended business need
- Raising concerns promptly during the sprint
- Committing to a dedicated block of availability on Thursday afternoons and Friday mornings for active integration testing and prompt sign-offs. Because of the compressed one week timeline, delayed feedback from the Product Owner directly impacts the release decision.

### Shared Responsibilities

The Software Engineering Team and client stakeholders share responsibility for:

- Keeping sprint scope stable
- Communicating clearly and promptly
- Using Jira as the shared source of truth
- Evaluating sprint progress against the sprint goals
- Making release readiness decisions based on testing results

## Sprint Timeline and Flow

A one week sprint follows a simple sequence: preparation before the sprint, focused development and testing during the sprint week, and a short stabilization period after the sprint if needed.

### Sprint Lifecycle Overview

| Phase / Day | Core Focus | Primary Environment | Key Deliverables & Hard Deadlines |
| :--- | :--- | :--- | :--- |
| **Week Prior** | Planning & Grooming | N/A | Lock scope; verify Definition of Ready (DoR); set Sprint Goals. |
| **Monday** | Kickoff & Launch | Local / Git | Brief kickoff; assign tasks; development begins. |
| **Tue — Wed** | Continuous Dev & Review | AWS Dev | Feature completion; **4-hour PR review SLA**; early feature testing. |
| **Wednesday** | Sync & Stage Setup | AWS Stage | Blockers cleared; **Environment Lead sync**; prep Stage for integration. |
| **Thursday** | Integration Testing | AWS Stage | **Thursday Afternoon:** Complete integrated release candidate testing. |
| **Friday** | Wrap-up & Ceremonies | AWS Stage / Prod | Release decision; Sprint Review & Retrospective. |
| **Week After** | Buffer / Handoff | AWS Prod | Max 1–2 days for hotfixes/deployment validation. *No new dev.* |

### Week Before the Sprint: Planning and Readiness

The week before the sprint is used to prepare the work so the sprint can begin cleanly.

The team holds a sprint planning meeting, typically one hour. The purpose of this meeting is to confirm that the sprint is ready to start, not to discover major missing requirements or debate whether work is ready.

Activities include:

- Review the Jira backlog
- Refine candidate issues
- Confirm that selected issues are ready to work
- Confirm team member availability during the sprint period
- Define sprint goals
- Confirm testing expectations
- Confirm release expectations
- Lock sprint scope

By the end of sprint planning, the sprint should contain a clear and realistic set of Jira issues, agreed sprint goals, and a shared understanding of what success looks like.

Sprint planning should also account for realistic development capacity. A one week sprint contains 40 theoretical working hours per developer, but meeting overhead (planning, kickoff, daily standups, review, retrospective) and standard administrative responsibilities (email, ServiceNow triage) significantly reduce available coding time. Teams should plan for a focus factor of 60 to 70 percent, or roughly 24 to 28 hours of actual development time per developer per sprint. Planning for the full 40 hours will consistently result in missed commitments. Teams that use story points rather than hours for estimation should calibrate their velocity against this adjusted capacity, not the raw 40 hour total. Story points abstract away individual variation and make sprint planning more predictable over time, but the underlying constraint remains the same: a one week sprint offers roughly 24 to 28 productive hours per developer.

### Monday: Sprint Kickoff and Development Start

Monday begins with a light sprint kickoff. The purpose is to confirm that the team understands the sprint goals, Jira board, and planned work for the week.

Activities include:

- Review sprint goals
- Confirm assignments
- Confirm the Jira sprint board is accurate
- Begin development work
- Create branches or pull requests as needed
- Update Jira issue status as work begins

The kickoff should be brief because major planning decisions should already be complete before the sprint starts.

The one week sprint follows the standard set of Agile ceremonies: sprint planning (week before), sprint kickoff (Monday), daily standups (Tuesday through Friday), sprint review (Friday), and sprint retrospective (Friday). These ceremonies provide the rhythm and accountability structure that keeps the compressed timeline on track.

### Daily Standup (Tuesday through Friday)

A mandatory, time-boxed 15-minute daily standup occurs each morning from Tuesday through Friday. In a one week sprint, a developer blocked for four hours loses the equivalent of a full day in a traditional two week sprint. The standup exists to surface blockers immediately so they can be resolved the same day. Each team member briefly states what they completed, what they plan to work on, and any blockers. The standup is not a status meeting or a planning session. Work should not sit unseen until the end of the sprint.

### Tuesday: Development, Review, and AWS Development Testing

Tuesday is a primary development day.

As individual issues are completed, they are reviewed, merged into the develop branch, and made available in the AWS development environment. This allows completed changes to be inspected before the formal integration testing window.

Activities include:

- Continue development
- Review code
- Review pull requests
- Merge completed work into the develop branch
- Deploy completed changes to the AWS development tier
- Test individual completed changes
- Update Jira as issues move forward
- Support client or stakeholder review of completed items where appropriate

Completed work should be made available for inspection as soon as practical. Work should not sit unseen until the end of the sprint.

To prevent a bottleneck of unreviewed pull requests accumulating into Wednesday and Thursday, a code review SLA applies throughout the sprint: pull requests must be reviewed within four business hours of submission. If a PR is submitted before noon, it should be reviewed by end of day. This keeps the integration pipeline flowing and prevents a traffic jam at the AWS stage environment on Thursday. When multiple developers need to deploy to the stage tier on the same day, the team should designate a rotating Environment Lead for each sprint who owns the deployment sequence to AWS Stage. The Environment Lead schedules a brief 30-minute sync on Wednesday afternoon to sequence migrations, resolve merge conflicts, and confirm the Stage environment is ready for Thursday integration testing. This prevents the ad hoc coordination that leads to environment collisions and lost time.

### Wednesday: Development, Review, and Integration Testing Preparation

Wednesday continues the development and review cycle.

Activities include:

- Complete as much planned sprint work as possible
- Continue code review
- Continue pull request review
- Merge completed work into the develop branch
- Continue AWS development tier testing
- Confirm which issues are ready for integration testing
- Prepare the AWS stage environment for integrated review

By the end of Wednesday, the team should have a clear sense of what is ready for Thursday integration testing.

### Thursday: Integration Testing in AWS Stage

Thursday afternoon is the primary integration testing window.

At this point, completed sprint work is evaluated together in the AWS stage environment. The stage environment represents the integrated application state and is used to determine whether the sprint work is ready for release.

Activities include:

- Review completed Jira issues in the AWS stage environment
- Test completed changes together as an integrated release candidate
- Confirm that related workflows still function correctly
- Look for conflicts between individually completed changes
- Identify integration issues or defects
- Update Jira with testing results
- Determine whether fixes are required before release
- Have developers address issues that come up during testing

Depending on severity, fixes may be completed Thursday afternoon, Friday, or during the short post sprint stabilization window.

### Friday: Final Testing, Release Decision, Review, and Retrospective

Friday is used for release readiness, final testing, and sprint closure.

If integration testing is successful, Friday may be used for release. If more validation is needed, Friday may become an additional integration testing day.

Activities may include:

- Complete final testing in AWS stage
- Address remaining release blockers
- Confirm release readiness
- Perform the production release if approved
- Review completed Jira issues
- Close or update sprint work
- Hold the sprint review
- Hold the sprint retrospective
- Confirm any follow up items

The sprint review and retrospective are typically held at the end of the sprint, usually on Friday. In some cases, these may occur Thursday afternoon if the team and stakeholders are ready.

## Sprint Review

The sprint review focuses on what was completed.

The review may include:

- Reviewing sprint goals
- Demonstrating completed work
- Confirming which Jira issues were completed
- Identifying work that was not completed
- Reviewing testing results
- Discussing release readiness
- Capturing follow up items for the backlog

The sprint review is not intended to reopen sprint scope. New requests should be captured in the backlog for future prioritization.

## Sprint Retrospective

The retrospective focuses on how the sprint went.

The retrospective may include:

- What worked well
- What created friction
- Whether the sprint scope was realistic
- Whether Jira issues were ready to work
- Whether testing happened early enough
- Whether integration testing was effective
- What should be adjusted for the next sprint

The retrospective should produce practical improvements for future sprint planning, development, testing, and release coordination.

## Week After the Sprint: Limited Stabilization and Release Completion

The week after the sprint is not a continuation of development. It exists strictly as a buffer for release verification, hotfix response, and operational handoff. Work that was not completed during the sprint returns to the backlog for reprioritization, it does not carry over automatically. If a team routinely relies on the week after to finish sprint work, that is a planning problem, not a scheduling feature.

This period should be limited to completing integration testing, addressing integration issues, and preparing the release for production. The expected duration is one to two days at most.

This follow up period is not an extension for adding new sprint scope. It is intended only for resolving issues related to sprint work already completed.

Appropriate post sprint activities include:

- Complete remaining integration testing
- Fix integration defects
- Retest fixes
- Confirm release readiness
- Complete the production release if it did not occur on Friday
- Update Jira
- Document any remaining follow up work

New requests or additional enhancements should be added to the Jira backlog and reviewed for a future sprint.

## After Release: Return to Operational Readiness

After the release is completed, the Software Engineering Team transitions back to other assigned project work.

The application remains supported in operational readiness mode. Under this model, new operational issues, production concerns, and support requests return to the normal ServiceNow intake process.

ServiceNow is used for operational support and production support requests. Jira remains the system for managing planned development work, sprint work, backlog items, and future enhancements.

## Jira Usage

Jira is the source of truth for sprint work.

Each sprint issue should have:

- A clear description
- Acceptance criteria or expected outcome
- Priority
- Assignee when appropriate
- Status updates during the sprint
- Testing notes where needed
- Clear resolution before closure

The sprint board should reflect the current state of work throughout the sprint. Jira should make it possible for the team and stakeholders to understand what is planned, what is in progress, what is ready for review, what is in testing, and what is complete.

## AWS Environment Usage

The sprint model uses AWS environments to support staged evaluation of work.

The AWS development tier supports continuous inspection. The AWS stage tier supports integrated release validation.

## Scope Change Guidance

New work should not be added to the sprint after it begins.

If a new issue is discovered during the sprint, it should be handled according to its urgency:

- **Critical production emergency:** Requires leadership review and explicit reprioritization before entering the active sprint.
- **Non-critical issue:** Added to the Jira backlog for future sprint planning.
- **Enhancement or feature request:** Routed to the backlog for prioritization in a future planning cycle.

This protects the sprint goals and prevents the one week sprint from becoming an open ended support window.

## Success Criteria

A one week sprint is successful when:

- Sprint goals were clear before work began
- Sprint scope remained stable
- Jira accurately reflected sprint progress
- Completed work was available for early review in AWS development
- Integrated work was tested in AWS stage
- Release readiness was evaluated clearly
- Production release occurred, or remaining release blockers were clearly understood
- Follow up work was limited and controlled
- New requests were routed to the backlog or ServiceNow as appropriate

## Summary

The one week sprint model provides a focused structure for completing a defined set of web application changes within a short time window.

The model depends on disciplined planning, stable scope, active Jira use, continuous integration, continuous inspection, and timely stakeholder testing. When used correctly, it allows the Software Engineering Team and client stakeholders to move a small, well defined set of changes from planning through development, integration testing, and potential release in a predictable and sustainable way.
