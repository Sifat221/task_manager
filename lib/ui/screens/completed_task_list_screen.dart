import 'package:flutter/material.dart';
import 'package:task_manager/data/models/task_model.dart';
import 'package:task_manager/data/models/task_status_count_model.dart';
import 'package:task_manager/data/service/network_caller.dart';
import 'package:task_manager/data/urls.dart';
import 'package:task_manager/ui/screens/add_new_task_screen.dart';
import 'package:task_manager/ui/widgets/centered_circular_progress_indicator.dart';
import 'package:task_manager/ui/widgets/snack_bar_message.dart';
import 'package:task_manager/ui/widgets/task_card.dart';
import 'package:task_manager/ui/widgets/task_count_summary_card.dart';

class CompletedTaskListScreen extends StatefulWidget {
  const CompletedTaskListScreen({super.key});

  @override
  State<CompletedTaskListScreen> createState() => _CompletedTaskListScreenState();
}

class _CompletedTaskListScreenState extends State<CompletedTaskListScreen> {
  bool _getCompletedTasksInProgress = false;
  bool _getTaskStatusCountInProgress = false;
  List<TaskModel> _completedTaskList = [];
  List<TaskStatusCountModel> _taskStatusCountList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCompletedTaskList();
      _getTaskStatusCountList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Visibility(
                visible: !_getTaskStatusCountInProgress,
                replacement: const CenteredCircularProgressIndicator(),
                child: ListView.separated(
                  itemCount: _taskStatusCountList.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return TaskCountSummaryCard(
                      title: _taskStatusCountList[index].id,
                      count: _taskStatusCountList[index].count,
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(width: 4),
                ),
              ),
            ),
            Expanded(
              child: Visibility(
                visible: !_getCompletedTasksInProgress,
                replacement: const CenteredCircularProgressIndicator(),
                child: ListView.builder(
                  itemCount: _completedTaskList.length,
                  itemBuilder: (context, index) {
                    return TaskCard(
                      taskType: TaskType.completed,
                      taskModel: _completedTaskList[index],
                      onStatusUpdate: () {
                        _getCompletedTaskList();
                        _getTaskStatusCountList();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onTapAddNewTaskButton,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _getCompletedTaskList() async {
    setState(() {
      _getCompletedTasksInProgress = true;
    });

    NetworkResponse response = await NetworkCaller
        .getRequest(url: Urls.getNewTasksUrl);


    if (response.isSuccess) {
      List<TaskModel> list = [];
      for (Map<String, dynamic> jsonData in response.body!['data']) {
        list.add(TaskModel.fromJson(jsonData));
      }
      setState(() {
        _completedTaskList = list;
        _getCompletedTasksInProgress = false;
      });
    } else {
      if (mounted) {
        showSnackBarMessage(context, response.errorMessage ?? "Failed to load completed tasks");
      }
      setState(() {
        _getCompletedTasksInProgress = false;
      });
    }
  }

  Future<void> _getTaskStatusCountList() async {
    setState(() {
      _getTaskStatusCountInProgress = true;
    });

    NetworkResponse response = await NetworkCaller.getRequest(url: Urls.getTaskStatusCountUrl);

    if (response.isSuccess) {
      List<TaskStatusCountModel> list = [];
      for (Map<String, dynamic> jsonData in response.body!['data']) {
        list.add(TaskStatusCountModel.fromJson(jsonData));
      }
      setState(() {
        _taskStatusCountList = list;
        _getTaskStatusCountInProgress = false;
      });
    } else {
      if (mounted) {
        showSnackBarMessage(context, response.errorMessage ?? "Failed to load task status counts");
      }
      setState(() {
        _getTaskStatusCountInProgress = false;
      });
    }
  }

  void _onTapAddNewTaskButton() {
    Navigator.pushNamed(context, AddNewTaskScreen.name).then((value) {
      if (value == true) {
        _getCompletedTaskList();
        _getTaskStatusCountList();
      }
    });
  }
}
