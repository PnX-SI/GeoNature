geonature.utils.logs
====================

.. py:module:: geonature.utils.logs


Classes
-------

.. autoapisummary::

   geonature.utils.logs.RequestIdFormatter


Functions
---------

.. autoapisummary::

   geonature.utils.logs.config_loggers


Module Contents
---------------

.. py:class:: RequestIdFormatter(fmt=None, datefmt=None, style='%', validate=True)

   Bases: :py:obj:`logging.Formatter`


   Formatter instances are used to convert a LogRecord to text.

   Formatters need to know how a LogRecord is constructed. They are
   responsible for converting a LogRecord to (usually) a string which can
   be interpreted by either a human or an external system. The base Formatter
   allows a formatting string to be specified. If none is supplied, the
   style-dependent default value, "%(message)s", "{message}", or
   "${message}", is used.

   The Formatter can be initialized with a format string which makes use of
   knowledge of the LogRecord attributes - e.g. the default value mentioned
   above makes use of the fact that the user's message and arguments are pre-
   formatted into a LogRecord's message attribute. Currently, the useful
   attributes in a LogRecord are described by:

   %(name)s            Name of the logger (logging channel)
   %(levelno)s         Numeric logging level for the message (DEBUG, INFO,
                       WARNING, ERROR, CRITICAL)
   %(levelname)s       Text logging level for the message ("DEBUG", "INFO",
                       "WARNING", "ERROR", "CRITICAL")
   %(pathname)s        Full pathname of the source file where the logging
                       call was issued (if available)
   %(filename)s        Filename portion of pathname
   %(module)s          Module (name portion of filename)
   %(lineno)d          Source line number where the logging call was issued
                       (if available)
   %(funcName)s        Function name
   %(created)f         Time when the LogRecord was created (time.time()
                       return value)
   %(asctime)s         Textual time when the LogRecord was created
   %(msecs)d           Millisecond portion of the creation time
   %(relativeCreated)d Time in milliseconds when the LogRecord was created,
                       relative to the time the logging module was loaded
                       (typically at application startup time)
   %(thread)d          Thread ID (if available)
   %(threadName)s      Thread name (if available)
   %(process)d         Process ID (if available)
   %(message)s         The result of record.getMessage(), computed just as
                       the record is emitted


   .. py:method:: format(record)

      Format the specified record as text.

      The record's attribute dictionary is used as the operand to a
      string formatting operation which yields the returned string.
      Before formatting the dictionary, a couple of preparatory steps
      are carried out. The message attribute of the record is computed
      using LogRecord.getMessage(). If the formatting string uses the
      time (as determined by a call to usesTime(), formatTime() is
      called to format the event time. If there is exception information,
      it is formatted using formatException() and appended to the message.



.. py:function:: config_loggers(config)

   Configuration des niveaux de logging/warnings
   et des hanlers


