# CyberTime - Hướng dẫn sử dụng

## Tổng quan

`CyberTime` là widget để chọn thời gian với iOS-style picker, hỗ trợ binding 2 chiều và tự động preserve type (DateTime hoặc String).

---

## 1. Basic Usage

### Simple Time Picker
```dart
CyberTime(
  text: row.bind("startTime"),
  label: "Giờ bắt đầu",
  hint: "Chọn giờ",
)
```

### With Initial Value
```dart
// String value
CyberTime(
  text: "14:30",
  label: "Giờ làm việc",
)

// DateTime value
CyberTime(
  text: DateTime.now(),
  label: "Giờ hiện tại",
)

// Binding
CyberTime(
  text: row.bind("appointmentTime"),
  label: "Giờ hẹn",
)
```

---

## 2. Format Options

### HH:mm (Giờ:Phút) - Mặc định
```dart
CyberTime(
  text: row.bind("time"),
  label: "Thời gian",
  format: "HH:mm", // 14:30
)
```

### HH:mm:ss (Giờ:Phút:Giây)
```dart
CyberTime(
  text: row.bind("exactTime"),
  label: "Thời gian chính xác",
  format: "HH:mm:ss", // 14:30:45
  showSeconds: true, // Hiển thị giây trong picker
)
```

---

## 3. Data Binding với CyberDataRow

### Binding 2 chiều
```dart
class TimePickerExample extends StatefulWidget {
  @override
  State<TimePickerExample> createState() => _TimePickerExampleState();
}

class _TimePickerExampleState extends State<TimePickerExample> {
  late CyberDataTable dt;
  late CyberDataRow row;

  @override
  void initState() {
    super.initState();
    dt = CyberDataTable(tableName: "Schedule");
    dt.addColumn("startTime", CyberDataType.text);
    dt.addColumn("endTime", CyberDataType.text);
    
    row = dt.newRow();
    row["startTime"] = "09:00";
    row["endTime"] = "17:00";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberTime(
          text: row.bind("startTime"),
          label: "Giờ bắt đầu",
        ),
        
        SizedBox(height: 16),
        
        CyberTime(
          text: row.bind("endTime"),
          label: "Giờ kết thúc",
        ),
        
        SizedBox(height: 16),
        
        // Display values
        Text("Từ ${row["startTime"]} đến ${row["endTime"]}"),
      ],
    );
  }
}
```

---

## 4. Type Preservation (Giữ nguyên kiểu dữ liệu)

### Input String → Output String
```dart
// Row setup
row["time"] = "14:30"; // String

// Widget
CyberTime(
  text: row.bind("time"),
  label: "Thời gian",
  onChanged: (newValue) {
    print(newValue); // "14:30" (String)
    print(newValue.runtimeType); // String
  },
)

// Result: row["time"] = "14:30" (String)
```

### Input DateTime → Output DateTime
```dart
// Row setup
row["appointment"] = DateTime(2025, 1, 15, 14, 30); // DateTime

// Widget
CyberTime(
  text: row.bind("appointment"),
  label: "Giờ hẹn",
  onChanged: (newValue) {
    print(newValue); // DateTime(2025, 1, 15, 16, 45)
    print(newValue.runtimeType); // DateTime
  },
)

// Result: row["appointment"] = DateTime(2025, 1, 15, 16, 45) (DateTime)
// Giữ nguyên ngày, chỉ thay đổi giờ/phút
```

---

## 5. Callbacks

### onChanged - Khi thay đổi giá trị
```dart
CyberTime(
  text: row.bind("time"),
  label: "Thời gian",
  onChanged: (newValue) {
    print("Time changed: $newValue");
    // Xử lý real-time
  },
)
```

### onLeaver - Khi rời khỏi control (user xác nhận)
```dart
CyberTime(
  text: row.bind("time"),
  label: "Thời gian",
  onLeaver: (finalValue) {
    print("User confirmed: $finalValue");
    // Trigger validation, save, etc.
  },
)
```

### Cả hai callbacks
```dart
CyberTime(
  text: row.bind("time"),
  label: "Thời gian",
  onChanged: (newValue) {
    // Update UI real-time
    setState(() {
      _selectedTime = newValue;
    });
  },
  onLeaver: (finalValue) {
    // Save to database
    _saveTimeToDatabase(finalValue);
  },
)
```

---

## 6. Styling & Customization

### Custom Colors
```dart
CyberTime(
  text: row.bind("time"),
  label: "Thời gian",
  backgroundColor: Colors.blue[50],
  focusColor: Colors.blue[200],
  labelStyle: TextStyle(
    fontSize: 16,
    color: Colors.blue[700],
    fontWeight: FontWeight.bold,
  ),
)
```

### Custom Icon
```dart
CyberTime(
  text: row.bind("workingHour"),
  label: "Giờ làm việc",
  icon: Icons.work_outline,
  backgroundColor: Colors.green[50],
)
```

### Hide Label
```dart
CyberTime(
  text: row.bind("time"),
  isShowLabel: false,
  hint: "Chọn giờ",
)
```

### Custom Decoration
```dart
CyberTime(
  text: row.bind("time"),
  decoration: InputDecoration(
    labelText: "Thời gian",
    prefixIcon: Icon(Icons.schedule),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: Colors.grey[100],
  ),
)
```

---

## 7. Validation & Constraints

### Validate Time Range
```dart
class TimeRangeValidation extends StatefulWidget {
  @override
  State<TimeRangeValidation> createState() => _TimeRangeValidationState();
}

class _TimeRangeValidationState extends State<TimeRangeValidation> {
  late CyberDataTable dt;
  late CyberDataRow row;

  @override
  void initState() {
    super.initState();
    dt = CyberDataTable(tableName: "WorkSchedule");
    dt.addColumn("startTime", CyberDataType.text);
    dt.addColumn("endTime", CyberDataType.text);
    
    row = dt.newRow();
    row["startTime"] = "09:00";
    row["endTime"] = "17:00";
  }

  bool _isValidTimeRange() {
    final start = _parseTime(row["startTime"]);
    final end = _parseTime(row["endTime"]);
    
    if (start == null || end == null) return false;
    
    // End time phải sau start time
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    return endMinutes > startMinutes;
  }

  TimeOfDay? _parseTime(dynamic value) {
    if (value is String) {
      final parts = value.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberTime(
          text: row.bind("startTime"),
          label: "Giờ bắt đầu",
          onLeaver: (_) {
            if (!_isValidTimeRange()) {
              context.showErrorMsg(
                "Giờ kết thúc phải sau giờ bắt đầu!",
              );
            }
          },
        ),
        
        SizedBox(height: 16),
        
        CyberTime(
          text: row.bind("endTime"),
          label: "Giờ kết thúc",
          onLeaver: (_) {
            if (!_isValidTimeRange()) {
              context.showErrorMsg(
                "Giờ kết thúc phải sau giờ bắt đầu!",
              );
            }
          },
        ),
      ],
    );
  }
}
```

### Business Hours Only (9AM - 6PM)
```dart
CyberTime(
  text: row.bind("workTime"),
  label: "Giờ làm việc",
  onLeaver: (value) {
    final time = _parseTime(value);
    if (time != null) {
      final minutes = time.hour * 60 + time.minute;
      final minMinutes = 9 * 60; // 9:00
      final maxMinutes = 18 * 60; // 18:00
      
      if (minutes < minMinutes || minutes > maxMinutes) {
        context.showErrorMsg(
          "Chỉ được chọn trong giờ làm việc (9:00 - 18:00)",
        );
        // Reset về giá trị hợp lệ
        row["workTime"] = "09:00";
      }
    }
  },
)
```

---

## 8. Visibility Binding

### Show/Hide Based on Condition
```dart
// Setup
row["showEndTime"] = "1"; // hoặc true

// Widget
CyberTime(
  text: row.bind("endTime"),
  label: "Giờ kết thúc",
  isVisible: row.bind("showEndTime"),
)
```

### Dynamic Visibility
```dart
class ConditionalTimeExample extends StatefulWidget {
  @override
  State<ConditionalTimeExample> createState() => _ConditionalTimeExampleState();
}

class _ConditionalTimeExampleState extends State<ConditionalTimeExample> {
  late CyberDataTable dt;
  late CyberDataRow row;

  @override
  void initState() {
    super.initState();
    dt = CyberDataTable(tableName: "Appointment");
    dt.addColumn("isAllDay", CyberDataType.text);
    dt.addColumn("startTime", CyberDataType.text);
    
    row = dt.newRow();
    row["isAllDay"] = "0";
    row["startTime"] = "09:00";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberCheckbox(
          text: row.bind("isAllDay"),
          label: "Cả ngày",
        ),
        
        SizedBox(height: 16),
        
        // Chỉ hiện khi không phải "Cả ngày"
        CyberTime(
          text: row.bind("startTime"),
          label: "Giờ bắt đầu",
          isVisible: row.bind("isAllDay"),
          // isVisible sẽ parse: "0" = false, "1" = true
          // Hoặc dùng logic nghịch đảo trong widget
        ),
      ],
    );
  }
}
```

---

## 9. Integration with CyberForm

### Complete Form Example
```dart
class AppointmentForm extends CyberContentViewForm {
  late CyberDataTable dt;
  late CyberDataRow row;

  @override
  void onInit() {
    dt = CyberDataTable(tableName: "Appointments");
    dt.addColumn("id", CyberDataType.text);
    dt.addColumn("date", CyberDataType.text);
    dt.addColumn("startTime", CyberDataType.text);
    dt.addColumn("endTime", CyberDataType.text);
    dt.addColumn("duration", CyberDataType.numeric);
    
    row = dt.newRow();
    row["date"] = DateTime.now().toString().split(' ')[0];
    row["startTime"] = "09:00";
    row["endTime"] = "10:00";
  }

  void _calculateDuration() {
    final start = _parseTime(row["startTime"]);
    final end = _parseTime(row["endTime"]);
    
    if (start != null && end != null) {
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      row["duration"] = (endMinutes - startMinutes) / 60.0;
    }
  }

  TimeOfDay? _parseTime(dynamic value) {
    if (value is String) {
      final parts = value.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
    return null;
  }

  Future<void> _saveAppointment() async {
    // Validate
    if (!_isValidTimeRange()) {
      await context.showErrorMsg(
        "Giờ kết thúc phải sau giờ bắt đầu!",
      );
      return;
    }

    showLoading("Đang lưu...");

    try {
      final response = await context.callApi(
        functionName: "SaveAppointment",
        parameter: "${row['date']}#${row['startTime']}#${row['endTime']}",
      );

      hideLoading();

      if (response.isValid()) {
        await context.showSuccess("Lưu lịch hẹn thành công!");
        closePopup(context, true);
      } else {
        await context.showErrorMsg(response.message);
      }
    } catch (e) {
      hideLoading();
      await context.showErrorMsg("Lỗi: $e");
    }
  }

  bool _isValidTimeRange() {
    final start = _parseTime(row["startTime"]);
    final end = _parseTime(row["endTime"]);
    
    if (start == null || end == null) return false;
    
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    return endMinutes > startMinutes;
  }

  @override
  Widget buildBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Tạo lịch hẹn",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          
          SizedBox(height: 24),
          
          CyberDate(
            text: row.bind("date"),
            label: "Ngày hẹn",
          ),
          
          SizedBox(height: 16),
          
          CyberTime(
            text: row.bind("startTime"),
            label: "Giờ bắt đầu",
            icon: Icons.access_time,
            onLeaver: (_) => _calculateDuration(),
          ),
          
          SizedBox(height: 16),
          
          CyberTime(
            text: row.bind("endTime"),
            label: "Giờ kết thúc",
            icon: Icons.access_time,
            onLeaver: (_) => _calculateDuration(),
          ),
          
          SizedBox(height: 16),
          
          // Display duration
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.timelapse, color: Colors.blue[700]),
                SizedBox(width: 8),
                Text(
                  "Thời lượng: ${row['duration'] ?? 0} giờ",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          CyberButton(
            label: "Lưu lịch hẹn",
            onClick: _saveAppointment,
          ),
        ],
      ),
    );
  }
}
```

---

## 10. Advanced Examples

### Work Schedule with Multiple Time Slots
```dart
class WorkScheduleForm extends StatefulWidget {
  @override
  State<WorkScheduleForm> createState() => _WorkScheduleFormState();
}

class _WorkScheduleFormState extends State<WorkScheduleForm> {
  late CyberDataTable dtSchedule;
  List<CyberDataRow> timeSlots = [];

  @override
  void initState() {
    super.initState();
    dtSchedule = CyberDataTable(tableName: "TimeSlots");
    dtSchedule.addColumn("startTime", CyberDataType.text);
    dtSchedule.addColumn("endTime", CyberDataType.text);
    
    // Add default slot
    _addTimeSlot();
  }

  void _addTimeSlot() {
    final row = dtSchedule.newRow();
    row["startTime"] = "09:00";
    row["endTime"] = "10:00";
    
    setState(() {
      timeSlots.add(row);
    });
  }

  void _removeTimeSlot(int index) {
    setState(() {
      timeSlots.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          itemCount: timeSlots.length,
          itemBuilder: (context, index) {
            final row = timeSlots[index];
            
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Ca ${index + 1}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeTimeSlot(index),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: CyberTime(
                            text: row.bind("startTime"),
                            label: "Bắt đầu",
                          ),
                        ),
                        
                        SizedBox(width: 16),
                        
                        Expanded(
                          child: CyberTime(
                            text: row.bind("endTime"),
                            label: "Kết thúc",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        SizedBox(height: 16),
        
        ElevatedButton.icon(
          onPressed: _addTimeSlot,
          icon: Icon(Icons.add),
          label: Text("Thêm ca làm"),
        ),
      ],
    );
  }
}
```

### Time Picker with Quick Selection Buttons
```dart
class QuickTimeSelection extends StatefulWidget {
  @override
  State<QuickTimeSelection> createState() => _QuickTimeSelectionState();
}

class _QuickTimeSelectionState extends State<QuickTimeSelection> {
  late CyberDataTable dt;
  late CyberDataRow row;

  final Map<String, String> quickTimes = {
    "9:00": "09:00",
    "12:00": "12:00",
    "14:00": "14:00",
    "17:00": "17:00",
  };

  @override
  void initState() {
    super.initState();
    dt = CyberDataTable(tableName: "QuickTime");
    dt.addColumn("time", CyberDataType.text);
    
    row = dt.newRow();
    row["time"] = "09:00";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CyberTime(
          text: row.bind("time"),
          label: "Thời gian",
        ),
        
        SizedBox(height: 12),
        
        Text(
          "Chọn nhanh:",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        
        SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          children: quickTimes.entries.map((entry) {
            return ChoiceChip(
              label: Text(entry.key),
              selected: row["time"] == entry.value,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    row["time"] = entry.value;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

---

## 11. Common Use Cases

### Meeting Room Booking
```dart
CyberGrid(
  children: [
    GridRow(
      widthColumn: "*, *",
      columns: [
        CyberTime(
          text: row.bind("startTime"),
          label: "Giờ bắt đầu",
          icon: Icons.login,
        ),
        CyberTime(
          text: row.bind("endTime"),
          label: "Giờ kết thúc",
          icon: Icons.logout,
        ),
      ],
    ),
  ],
)
```

### Restaurant Reservation
```dart
Column(
  children: [
    CyberDate(
      text: row.bind("date"),
      label: "Ngày đặt bàn",
    ),
    
    SizedBox(height: 16),
    
    CyberTime(
      text: row.bind("reservationTime"),
      label: "Giờ đặt bàn",
      hint: "Chọn giờ (11:00 - 22:00)",
    ),
  ],
)
```

### Doctor Appointment
```dart
Column(
  children: [
    CyberDate(
      text: row.bind("appointmentDate"),
      label: "Ngày khám",
    ),
    
    SizedBox(height: 16),
    
    CyberTime(
      text: row.bind("appointmentTime"),
      label: "Giờ khám",
      icon: Icons.medical_services,
    ),
  ],
)
```

### Alarm Clock
```dart
CyberTime(
  text: row.bind("alarmTime"),
  label: "Đặt báo thức",
  icon: Icons.alarm,
  backgroundColor: Colors.orange[50],
  onLeaver: (time) {
    // Schedule notification
    _scheduleAlarm(time);
  },
)
```

---

## 12. Tips & Best Practices

### ✅ DO - Nên làm

```dart
// ✅ Sử dụng binding cho data 2 chiều
CyberTime(
  text: row.bind("time"),
  label: "Thời gian",
)

// ✅ Validate trong onLeaver
CyberTime(
  text: row.bind("endTime"),
  label: "Giờ kết thúc",
  onLeaver: (value) {
    if (!_isValidTimeRange()) {
      context.showErrorMsg("Invalid time range!");
    }
  },
)

// ✅ Hiển thị seconds khi cần chính xác
CyberTime(
  text: row.bind("exactTime"),
  label: "Thời gian chính xác",
  format: "HH:mm:ss",
  showSeconds: true,
)

// ✅ Custom style phù hợp với app theme
CyberTime(
  text: row.bind("time"),
  label: "Thời gian",
  backgroundColor: Colors.blue[50],
  icon: Icons.access_time,
)
```

### ❌ DON'T - Không nên làm

```dart
// ❌ Không sử dụng format không hợp lệ
CyberTime(
  format: "HH-mm-ss", // Sai, phải dùng ":"
)

// ❌ Không validate time range
CyberTime(
  text: row.bind("endTime"),
  // Thiếu validation, user có thể chọn end < start
)

// ❌ Không cần showSeconds nhưng vẫn bật
CyberTime(
  format: "HH:mm", // Không có ss
  showSeconds: true, // Không cần thiết
)
```

---

## 13. Troubleshooting

### Issue: Giá trị không cập nhật

```dart
// ❌ SAI
String selectedTime = "09:00";
CyberTime(
  text: selectedTime, // Không bind
  onChanged: (newTime) {
    selectedTime = newTime; // Không trigger rebuild
  },
)

// ✅ ĐÚNG
CyberTime(
  text: row.bind("time"), // Binding
  onChanged: (newTime) {
    // Auto update through binding
  },
)
```

### Issue: Type mismatch

```dart
// ❌ SAI - Expect String nhưng nhận DateTime
row["time"] = DateTime.now();
// Widget vẫn expect String format "HH:mm"

// ✅ ĐÚNG - CyberTime tự động handle cả 2
CyberTime(
  text: row.bind("time"), // Auto parse cả String và DateTime
)
```

---

## Feature Summary

✅ Support cả **DateTime** và **String** input
✅ **Type preservation** - Trả về đúng kiểu đầu vào
✅ **2-way binding** với CyberDataRow
✅ **iOS-style picker** với smooth scrolling
✅ Support **giây** (HH:mm:ss)
✅ **onChanged** và **onLeaver** callbacks
✅ **Visibility binding**
✅ Custom **styling** và **icons**
✅ **Read-only** text field
✅ **Enabled/disabled** state
✅ Tự động format hiển thị
✅ Visual feedback cho selected value
