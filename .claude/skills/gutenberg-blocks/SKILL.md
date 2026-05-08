---
name: gutenberg-blocks
description: Use when the user mentions "class schedule", "campus directory", "course catalog", "gutenberg blocks", or "custom functionality" plugin. Provides file locations, architecture context, and repo structure.
user-invocable: false
---

# Repository Structure

This project has **nested git repos**. The outer repo (`wp-dev.ucsc`) is the WordPress environment, but most active development happens in two plugin repos nested inside it:

| Repo | Path | Purpose |
|------|------|---------|
| **ucsc-gutenberg-blocks** | `public/wp-content/plugins/ucsc-gutenberg-blocks/` | Class Schedule, Campus Directory, Course Catalog blocks |
| **ucsc-custom-functionality** | `public/wp-content/plugins/ucsc-custom-functionality/` | Custom WordPress functionality plugin |

**Important — all git operations must target the correct repo:**

- **Any git command** (`git log`, `git diff`, `git status`, `git blame`, `git commit`, etc.) related to these plugins must use `-C` to target the nested repo, or be run from within the plugin directory. The outer `wp-dev.ucsc` repo will NOT contain the plugin commit history.
- Use `git -C public/wp-content/plugins/ucsc-gutenberg-blocks log` (not `git log`) when investigating block changes.
- Use `git -C public/wp-content/plugins/ucsc-custom-functionality log` for custom functionality changes.
- Each plugin has its own `.git`, branches, and remotes completely independent of the outer repo.

---

# UCSC Gutenberg Blocks Plugin

All block source code lives under `public/wp-content/plugins/ucsc-gutenberg-blocks/`.

## Class Schedule

| Layer | Files |
|-------|-------|
| Block editor (JS) | `src/blocks/ClassSchedule.js` |
| Components | `src/components/ClassSchedule/classschedule.js`, `src/components/ClassSchedule/classschedule.css` |
| Shared dropdowns | `src/components/DepartmentDropdown.js`, `src/components/DivisionDropdown.js`, `src/components/SubjectDropdown.js` |
| PHP class | `classes/ClassSchedule.php` |
| API | `src/API/Course_Schedule_API.php` |
| Template | `templates/ClassScheduleTemplate.php` |
| Tests | `src/blocks/__tests__/ClassSchedule.test.js` |

## Campus Directory

| Layer | Files |
|-------|-------|
| Block editor (JS) | `src/blocks/CampusDirectory.js` |
| Components | `src/components/CampusDirectory/` (AutomatedFeeds, CampusDirectoryDepartmentDropdown, CheckboxGroupControl, InformationToDisplay, InformationToDisplayTable, PageLayout, PeopleAndInformation) |
| Styles | `src/components/CampusDirectory/campusdirectory.css`, `directoryprofile.css`, `directoryprofileshortcode.css`, `editor.css` |
| PHP classes | `classes/CampusDirectory.php`, `classes/CampusDirectoryAPI.php`, `classes/CampusDirectoryShortcode.php` |
| Templates | `templates/CampusDirectoryTemplate.php`, `templates/DirectoryProfileTemplate.php` |
| Tests | `src/blocks/__tests__/CampusDirectory.test.js` |

## Course Catalog

| Layer | Files |
|-------|-------|
| Block editor (JS) | `src/blocks/CourseCatalog.js` |
| Components | `src/components/CourseCatalog/coursecatalog.css`, `tablesorter.css`, `tablesorter.js` |
| Shared dropdowns | `src/components/DepartmentDropdown.js`, `src/components/SubjectDropdown.js` |
| PHP class | `classes/CourseCatalog.php` |
| Template | `templates/CourseDetailTemplate.php` |
| Tests | `src/blocks/__tests__/CourseCatalog.test.js` |

## Shared Resources

- **Shared components:** `src/components/shared/` (static-directory-page.css, templates.css)
- **Dropdown components** used by multiple blocks: `DepartmentDropdown.js`, `DivisionDropdown.js`, `SubjectDropdown.js`
- **Plugin entry point:** `index.php`
- **JS entry point:** `src/index.js`
- **Build output:** `build/`
- **Site settings:** `classes/SiteSettings.php`

## Architecture Notes

- Each block has a **JS block definition** (`src/blocks/`), **React components** (`src/components/<BlockName>/`), a **PHP server-side class** (`classes/`), and a **PHP template** (`templates/`).
- The API layer in `src/API/Course_Schedule_API.php` is shared by Class Schedule and Course Catalog.
- Tests use Jest (`jest-unit.config.js`).
- Build tooling is configured in `package.json`.
