import re

file_path = r"C:\Users\hp\Desktop\EthioWorkforce\frontend\lib\features\attendance\presentation\widgets\hierarchical_attendance_list.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Remove _showMarkAttendanceMenu and _showAttendanceActions
# We don't need them because they rely on onMarkAttendance and onUnmarkAttendance, which are removed!
# Let's find and remove them.
def remove_method(content, method_name):
    # Find start of method
    idx = content.find(f"  void {method_name}")
    if idx == -1:
        return content
    
    # Simple brace matching to remove the whole method
    start = idx
    brace_count = 0
    in_method = False
    
    for i in range(idx, len(content)):
        if content[i] == '{':
            brace_count += 1
            in_method = True
        elif content[i] == '}':
            brace_count -= 1
            if in_method and brace_count == 0:
                end = i + 1
                return content[:start] + content[end:]
    return content

content = remove_method(content, "_showMarkAttendanceMenu")
content = remove_method(content, "_showAttendanceActions")

# 2. Fix duplicate _getStatusColor
# The replacement injected it before _getRoleLabel, but the file already had it in _buildWorkerItem?
# Actually, the original HierarchicalWorkersList had _getStatusColor inside? 
# Wait, HierarchicalWorkersList has _getStatusColor already? Let me check by regex.
# Let's just remove the FIRST occurrence of _getStatusColor and _getStatusIcon
content = remove_method(content, "_getStatusColor")
content = remove_method(content, "_getStatusIcon")

# Oh wait, we WANT to inject them once, so let's reinject them correctly at the end of the class.
# We will just remove ALL occurrences and inject at the very end.
while "  Color _getStatusColor" in content:
    content = remove_method(content, "_getStatusColor")
while "  IconData _getStatusIcon" in content:
    content = remove_method(content, "_getStatusIcon")
    
# Wait, I also need to make sure the missing brace is fixed. The expected token error is at the end:
# hierarchical_attendance_list.dart:946:6 - Expected to find ')'. - expected_token
# This is probably because of the InkWell injection!
# child: InkWell(
#    onTap: ...
#    child: Card(
# We replaced child: Card( with child: InkWell(... child: Card(, but we forgot to close the InkWell parenthesis!
# Let's fix that.
# The card is closed with       ), at the end of _buildWorkerItem.

# Actually, the easiest way to fix the expected token is to find the end of _buildWorkerItem and add ) to child: InkWell(...).
content = content.replace("        ),\n      ),\n    );", "        ),\n      ),\n    ), // Close InkWell\n    ); // Close Container")

# And append the status methods before the last }
status_methods = '''
  Color _getStatusColor(String status) {
    switch (status) {
      case 'present': return Colors.green;
      case 'absent': return Colors.red;
      case 'late': return Colors.orange;
      case 'excused': return Colors.blue;
      case 'leave': return Colors.purple;
      case 'half_day': return Colors.amber;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present': return Icons.check_circle;
      case 'absent': return Icons.cancel;
      case 'late': return Icons.access_time;
      case 'excused': return Icons.event_available;
      case 'leave': return Icons.beach_access;
      case 'half_day': return Icons.schedule;
      default: return Icons.help;
    }
  }
}
'''
content = content.rstrip()
if content.endswith("}"):
    content = content[:-1] + status_methods

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
print("Done")
