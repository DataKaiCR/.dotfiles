-- Note Manager - Main Entry Point
-- This module provides a unified API for note management across different note types.
-- The implementation is split into specialized modules for better organization.

local M = {}

-- Load all submodules
local core = require("datakai.utils.note_manager.core")
local daily = require("datakai.utils.note_manager.daily")
local zettel = require("datakai.utils.note_manager.zettel")
local project = require("datakai.utils.note_manager.project")
local meeting = require("datakai.utils.note_manager.meeting")
local inbox = require("datakai.utils.note_manager.inbox")

-- Re-export core functions
M.create_note = core.create_note
M.create_note_with_content = core.create_note_with_content
M.create_note_in_folder = core.create_note_in_folder
M.fix_note_format = core.fix_note_format
M.process_note_after_creation = core.process_note_after_creation
M.create_quick_note = core.create_quick_note
M.weekly_review = core.weekly_review

-- Re-export daily note functions
M.create_daily_note = daily.create_daily_note

-- Re-export zettel functions
M.create_zettel = zettel.create_zettel

-- Re-export project functions
M.create_project_note = project.create_project_note
M.extract_project_info = project.extract_project_info
M.update_project_info = project.update_project_info

-- Re-export meeting functions
M.create_meeting_note = meeting.create_meeting_note

-- Re-export inbox functions
M.capture_to_inbox = inbox.capture_to_inbox
M.process_inbox_line = inbox.process_inbox_line
M.capture_with_context = inbox.capture_with_context

return M
