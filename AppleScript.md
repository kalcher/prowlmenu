## AppleScript interface ##

prowlmenu currently supports one AppleScript command:

**send** **message** _string_ : send the message contained in _string_

## Example ##

```
tell application "prowlmenu"
	send message "Hello World!"
end tell
```