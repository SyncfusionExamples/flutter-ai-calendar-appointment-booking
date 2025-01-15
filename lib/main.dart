import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_chat/assist_view.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: _AICalendar(),
    ),
  ));
}

class _AICalendar extends StatefulWidget {
  @override
  _AICalendarState createState() => _AICalendarState();
}

class _AICalendarState extends State<_AICalendar>
    with SingleTickerProviderStateMixin {
  _AICalendarState();
  final List<Appointment> _scheduledAppointments = <Appointment>[];
  final List<CalendarResource> _resources = <CalendarResource>[];
  final List<String> _appointmentBookedTimes = [];
  final List<String> _subjects = <String>[
    'Latest SDK changes Review',
    'User Guide Review',
    'Blog Review',
  ];
  final String _name = 'John';
  final String _userImage = 'images/People_Circle8.png';
  final Color _appointmentColor = const Color(0xFF0F8644);
  final AssistMessageAuthor _user = const AssistMessageAuthor(
    id: '8ob3-b720-g9s6-25s8',
    name: 'Farah',
  );  final AssistMessageAuthor _ai = const AssistMessageAuthor(
    id: '8ob3-b720-g9s6-25s0',
    name: 'AI',
  );
  late _EventDataSource _events;
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<AssistMessage> _messages;
  late TextEditingController _textController;
  Key _assistViewKey = UniqueKey();
  bool _isLoading = false;
  bool _isPressed = false;
  bool _showButtons = true;
  bool _isFirstTime = true;
  final List<Content> _conversationHistory = [];
  final DateTime _todayDate = DateTime.now();
  DateTime _selectedDateTime = DateTime.now();
  String _managerName = '';
  String _appointmentTime = '';
  Appointment? _selectedAppointment;
  String _subject = '';
  Color _primaryColor = Colors.transparent;
  Brightness _brightness = Brightness.light;
  // Add your API key here to communicate with AI. 
  final String _assistApiKey = '';
  final String _appointmentBooked =
      'Your appointment has been successfully booked';

  @override
  void initState() {
    // Update calendar appointments at load time.
    _addResources();
    _addAppointments();
    _events = _EventDataSource(
      _scheduledAppointments,
      _resources,
    );

    // Assistview text handling.
    _textController = TextEditingController()..addListener(_handleTextChange);
    _messages = <AssistMessage>[];
    // AI animated button.
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _primaryColor = Theme.of(context).primaryColor;
    _brightness = Theme.of(context).brightness;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double sidebarWidth =
              constraints.maxWidth > 600 ? 360 : constraints.maxWidth;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: _buildCalendar(
                        _events,
                      ),
                    ),
                  ],
                ),
                AnimatedPositioned(
                  duration: Duration.zero,
                  right: _isPressed ? 0 : -sidebarWidth,
                  top: 48,
                  bottom: 0,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Container(
                        width: sidebarWidth,
                        decoration: BoxDecoration(
                          color:
                              _brightness == Brightness.light
                                  ? const Color(0xFFFFFBFE)
                                  : const Color(0xFF1C1B1F),
                          border: Border.all(color: Colors.grey, width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 6.0,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: SelectionArea(
                          child: Column(
                            children: [
                              Container(
                                height: 50,
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  border: Border.all(
                                      color: _primaryColor, width: 0.5),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'AI Assistant',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _brightness ==
                                                Brightness.light
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.autorenew,
                                            color: _brightness ==
                                                    Brightness.light
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          onPressed: _refreshView,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            color:_brightness ==
                                                    Brightness.light
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          onPressed: _toggleSidebar,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: StatefulBuilder(
                                  builder: (BuildContext context,
                                      StateSetter setState) {
                                    return Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: _buildAssistView(constraints),
                                        ),
                                        if (_isLoading)
                                          const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 2.0,
                  right: 1.0,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (BuildContext context, Widget? child) {
                      return Container(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
                        child: Transform.scale(
                          scale: _isPressed ? 1.0 : _animation.value,
                          child: FloatingActionButton(
                            backgroundColor: _primaryColor,
                            mini: true,
                            onPressed: _toggleSidebar,
                            child: Image.asset(
                              'images/ai_assist_view.png',
                              height: 30,
                              width: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_showButtons)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              'How can I assist with your project review?',
              style: TextStyle(
                fontSize: 16.0,
                color: _brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_showButtons)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 20, 0),
                child: _buildManagerView(
                  context,
                  constraints,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildComposer(BuildContext context) {
    return TextField(
      maxLines: 5,
      minLines: 1,
      controller: _textController,
      decoration: InputDecoration(
        fillColor: Theme.of(context).colorScheme.surfaceContainer,
        filled: true,
        hintText: 'Type here...',
        border: const UnderlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.send,
            color: _textController.text.isNotEmpty
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFF9E9E9E),
          ),
          onPressed: _textController.text.isNotEmpty
              ? () {
                  setState(() {
                    _messages.add(
                      AssistMessage.request(
                        time: DateTime.now(),
                        author: _user,
                        data: _textController.text,
                      ),
                    );
                    _showButtons = false;
                    _generateAIResponse(_textController.text);
                    _textController.clear();
                  });
                }
              : null,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  void _handleTextChange() {
    setState(() {});
  }

  ElevatedButton _buildManagerView(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return ElevatedButton(
      onPressed: () => {},
      style: ElevatedButton.styleFrom(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: CircleAvatar(
              radius: 35,
              backgroundImage: AssetImage(_userImage),
            ),
          ),
          SizedBox(height: constraints.maxWidth > 600 ? 10 : 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 10, 10),
            child: Text(
              constraints.maxWidth < 600
                  ? 'Book \n review meeting with \n Manager $_name'
                  : 'Book review meeting \n with Manager $_name',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshView() async {
    setState(() {
      _messages.clear();
      _showButtons = false;
      _isLoading = true;
      _conversationHistory.clear();
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _showButtons = true;
      _isLoading = false;
      _assistViewKey = UniqueKey();
      _isFirstTime = true;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isPressed = !_isPressed;
    });
  }

  void _convertAIResponse(String response) {
    {
      // Split the details from the response
      final List<String> lines = response.split('\n');
      // Create a map to store the information
      final Map<String, String> appointmentDetails = {};
      // Iterate over the lines to store them in the map
      for (final String line in lines) {
        if (line.contains('=')) {
          final List<String> parts = line.split(' = ');
          appointmentDetails[parts[0].trim()] = parts[1].trim();
        }
      }
      String startTime;
      String date;
      setState(
        () {
          _managerName = appointmentDetails['ManagerName']!;
          _appointmentTime = appointmentDetails['Time']!;
          startTime = _appointmentTime.split(' - ')[0].toUpperCase();
          _appointmentTime = startTime;
          date = appointmentDetails['Date']!;
          _appointmentBookedTimes.add(date);
          final DateFormat dateFormat = DateFormat('dd-MM-yyyy h:mm a');
          _selectedDateTime = dateFormat.parse('$date $startTime');
          _subject = appointmentDetails['MeetingAgenta']!;
          if (_managerName.isNotEmpty &&
              _appointmentTime.isNotEmpty &&
              _subject.isNotEmpty) {
            _confirmAppointmentWithEmployee();
          }
        },
      );
    }
  }

  void _confirmAppointmentWithEmployee() {
    _selectedAppointment = null;
    final DateTime now = DateTime.now();
    DateTime dateTime = DateTime.now();
    switch (_appointmentTime) {
      case '9 AM':
      case '9:00 AM':
        dateTime = DateTime(now.year, now.month, now.day, 9);
        break;
      case '9:30 AM':
        dateTime = DateTime(now.year, now.month, now.day, 9, 30);
        break;
      case '10 AM':
      case '10:00 AM':
        dateTime = DateTime(now.year, now.month, now.day, 10);
        break;
      case '10:30 AM':
      case '10.30 AM':
        dateTime = DateTime(now.year, now.month, now.day, 10, 30);
        break;
      case '11 AM':
      case '11:00 AM':
        dateTime = DateTime(now.year, now.month, now.day, 11);
        break;
      case '11:30 AM':
      case '11.30 AM':
        dateTime = DateTime(now.year, now.month, now.day, 11, 30);
      case '12 PM':
      case '12:00 PM':
        dateTime = DateTime(now.year, now.month, now.day, 12);
        break;
      case '12:30 PM':
      case '12.30 PM':
        dateTime = DateTime(now.year, now.month, now.day, 12, 30);
        break;
      case '2 PM':
      case '2:00 PM':
        dateTime = DateTime(now.year, now.month, now.day, 14);
        break;
      case '2:30 PM':
      case '2.30 PM':
        dateTime = DateTime(now.year, now.month, now.day, 14, 30);
        break;
      case '3 PM':
      case '3:00 PM':
        dateTime = DateTime(now.year, now.month, now.day, 15);
        break;
      case '3:30 PM':
      case '3.30 PM':
        dateTime = DateTime(now.year, now.month, now.day, 15, 30);
        break;
      case '4 PM':
      case '4:00 PM':
        dateTime = DateTime(now.year, now.month, now.day, 16);
        break;
      case '4:30 PM':
      case '4.30 PM':
        dateTime = DateTime(now.year, now.month, now.day, 16, 30);
        break;
      case '5 PM':
      case '5:00 PM':
        dateTime = DateTime(now.year, now.month, now.day, 17);
        break;
    }
    final selectedResource = _resources.firstWhere(
        (resource) => resource.displayName == _managerName,
        orElse: () => _resources.first);
    setState(
      () {
        final List<Appointment> appointmentList = <Appointment>[];
        if (_selectedAppointment == null) {
          _subject = _subject.isEmpty ? '(No title)' : _subject;
          final newAppointment = Appointment(
            startTime: _selectedDateTime,
            endTime: _selectedDateTime.add(const Duration(minutes: 30)),
            resourceIds: [selectedResource.id],
            color: selectedResource.color,
            subject: _subject,
          );
          appointmentList.add(newAppointment);
          _events.appointments!.add(newAppointment);
          SchedulerBinding.instance.addPostFrameCallback(
            (Duration duration) {
              _events.notifyListeners(
                  CalendarDataSourceAction.add, appointmentList);
            },
          );
          _selectedAppointment = newAppointment;
        }
      },
    );
  }

  Future<void> _generateAIResponse(String prompt) async {
    String? responseText;
    try {
      if (_assistApiKey.isNotEmpty) {
        final aiModel = GenerativeModel(
          model: 'gemini-1.5-flash-latest',
          apiKey: _assistApiKey,
        );
        if (_isFirstTime) {
          prompt = _generatePrompt(prompt);
          _isFirstTime = false;
        }

        _conversationHistory.add(Content.text('User Input$prompt'));
        final GenerateContentResponse response =
            await aiModel.generateContent(_conversationHistory);
        responseText = (response.text ?? '').trim();
        _conversationHistory.add(Content.text(responseText));
      } else {
        responseText =
            'API key is missing. Please provide a valid API key to generate a response.';
      }
      if (responseText.contains(_appointmentBooked) ||
          responseText.contains(
              'Your appointment with Manager $_name has been booked')) {
        _convertAIResponse(responseText);
      }
    } catch (e) {
      responseText = '$e.';
    } finally {
      // Handle finally
    }
    setState(
      () {
        _messages.add(
          AssistMessage.response(
            data: responseText!,
            time: DateTime.now(),
            author: _ai,
          ),
        );
      },
    );
  }

  String _generatePrompt(String request) {
    String aiPrompt = """
  You are an intelligent appointment booking assistant designed to book project review appointments step-by-step.  
  Focus on the user's inputs, confirm details at each step, and proceed only after validation. 
  Always remember the current step and user preferences until the appointment is finalized.
  When responding to the user:
  - Do not include any extra information, such as the phrase 'step 1', 'step 2', 'AI response', or any symbols.
  - Respond only with the relevant questions or confirmations needed to complete the booking process.
  - Ensure that the conversation flows smoothly and logically based on the user's input.
  
  ### Steps:
  1. **Date Confirmation**: 
      Greet the user with a welcome message: "Welcome to the Project Review Appointment Booking Assistant! I’m here to help you book an project review appointment step-by-step."
     
     - Ask the user for a valid date (dd-mm-yyyy).
     - Compare the user selected date with today's date ($_todayDate).
       - If the selected date is in the past, politely ask the user to select today or a future date.
       - If the selected date is today ($_todayDate) or future date, proceed to the next step.
       - Ensure the date format is correct (dd-mm-yyyy). If the input is invalid or the wrong format is used, ask the user to correct it.
  
  2. **Project Reviewer Selection**:
     Do not ask for the project reviewers name, because its always $_name. Validate the input using the following logic:
       - Convert the input to lowercase for comparison.
       - If the input does not match $_name (after converting and stripping), kindly inform the user like $_name only available for project review.
  
  3. **Time Slot Generation**:
     Generate 5 slots alone evenly spaced 30-minute slots between 9 AM and 5 PM for the project review and do not share 1PM to 2PM, because its lunch time and list them below. After the user selects a time slot, validate that the selection is one of the generated options. If the input is invalid, kindly prompt the user to choose a valid time slot.
  
  4. **Time Slot Confirmation**:
     After the user selects a time slot, confirm that the selected slot matches one of the generated options. If selected 1 to 2 PM, inform like its lunch time, so select another time. If correct, proceed; if not, ask the user to select a valid time slot. If the selected time is already have appointment in $_appointmentBookedTimes, mention already appointment book in that time, so select alternative time. 
  
  5. **Subject Selection**:
    Ask the user to choose from predefined subjects:
  
     - And List these subjects below: 
       • Blog Review
       • Latest SDK support  
       • Bug Review
       
     Validate the input using the following logic:
       - Convert the input to lowercase for comparison.
       - Ensure the input matches one of the available subjects, regardless of case.
       - If the input is invalid or unrecognized, kindly ask the user to choose from the listed subjects.
  
  6. **Booking Confirmation**:
     Once all steps have been successfully completed, respond with the booking confirmation:
     - If the inputs are valid:
       Respond with:
       "Your appointment with Manager $_name has been booked."
       Provide the details in this format:  
       ManagerName = _managerName 
       Date = _date   
       Time = _appointmentTime  
       MeetingAgenta = _subject  
  
       "Your project review meeting has been successfully booked! Refresh to book a new appointment."


   7. If the $request contains the time, subject and with or without date, ignore all steps and directly share the 6 the step. If the date is not given share the $_todayDate with this format dd-MM-yyyy and do not add hours minutes in step 6 _date field. Change the given time to hh:mm a format and set to step 6 _appointmentTime field   
  
  ### General Rules:
  - Validate inputs step-by-step before proceeding.
  - Do not jump back to previous steps once completed.
  - For invalid inputs, respond with polite clarification and ask for the correct input.
  - Always ensure that the assistant remembers the current step and doesn't make assumptions.
  - After the booking is completed, if the user tries to request anything unrelated, respond with: "Your previous appointment has already been booked successfully. To book a new appointment, please refresh and start the process again."
  """;
    return aiPrompt;
  }

  void _addResources() {
    _resources.add(
      CalendarResource(
        displayName: _name,
        id: 'SF0001',
        color: _appointmentColor,
        image: ExactAssetImage(_userImage),
      ),
    );
  }

  void _addAppointments() {
    const List<int> appointmentTime = [9, 11, 14];
    final DateTime date = DateTime.now();
    final List<Object> resourceIds = <Object>[_resources[0].id];
    for (int i = 0; i < _subjects.length; i++) {
      final int startHour = appointmentTime[i];
      final DateTime meetingStartTime =
          DateTime(date.year, date.month, date.day, startHour);
      _appointmentBookedTimes.add(meetingStartTime.toString());
      _scheduledAppointments.add(
        Appointment(
          startTime: meetingStartTime,
          endTime: meetingStartTime.add(const Duration(minutes: 30)),
          subject: _subjects[i],
          color: _appointmentColor,
          resourceIds: resourceIds,
        ),
      );
    }
  }

  SfCalendar _buildCalendar(CalendarDataSource calendarDataSource) {
    return SfCalendar(
      view: CalendarView.timelineDay,
      timeSlotViewSettings: const TimeSlotViewSettings(
        timeInterval: Duration(minutes: 30),
        timeIntervalWidth: 100,
        timeRulerSize: 25,
        timeFormat: 'h:mm',
        startHour: 9,
        endHour: 17,
        dayFormat: 'EEEE',
        dateFormat: 'dd',
      ),
      dataSource: calendarDataSource,
    );
  }

  SfAIAssistView _buildAssistView(BoxConstraints constraints) {
    return SfAIAssistView(
      key: _assistViewKey,
      messages: _messages,
      placeholderBuilder: (BuildContext context) =>
          _buildPlaceholder(context, constraints),
      responseBubbleSettings: const AssistBubbleSettings(
        showUserAvatar: false,
        widthFactor: 0.8,
        textStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          height: 20.0 / 14.0,
          letterSpacing: 0.1,
          textBaseline: TextBaseline.alphabetic,
          decoration: TextDecoration.none,
        ),
      ),
      requestBubbleSettings: AssistBubbleSettings(
        showUserAvatar: false,
        widthFactor: 0.95,
        contentBackgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          height: 20.0 / 14.0,
          letterSpacing: 0.1,
          textBaseline: TextBaseline.alphabetic,
          decoration: TextDecoration.none,
        ),
      ),
      composer: AssistComposer.builder(
        builder: (BuildContext context) {
          return _buildComposer(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _messages.clear();
    _controller.dispose();
    _textController.dispose();
    _events.appointments!.clear();
    _scheduledAppointments.clear();
    _resources.clear();
    _subjects.clear();
    super.dispose();
  }
}

class _EventDataSource extends CalendarDataSource {
  _EventDataSource(
    List<Appointment> events,
    List<CalendarResource> resourceList,
  ) {
    appointments = events;
    resources = resourceList;
  }
}
