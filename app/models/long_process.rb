
#=======================================================================
#This class takes a long_running task as input and breaks it into a set
#of subtasks. Each subtask has an id which is part of a sequential list
#of ids (tasks). This class- representing the entire long running process-
#waits in session state to be called from a client- which is polling the server
#- to obtain the next task id- the client then calls execute on this class's
#-process (represented by a controller) specifying the id
#=======================================================================
class LongProcess






end