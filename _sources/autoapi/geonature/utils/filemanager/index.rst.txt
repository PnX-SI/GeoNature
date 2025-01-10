geonature.utils.filemanager
===========================

.. py:module:: geonature.utils.filemanager


Functions
---------

.. autoapisummary::

   geonature.utils.filemanager.removeDisallowedFilenameChars
   geonature.utils.filemanager.delete_recursively
   geonature.utils.filemanager.generate_pdf


Module Contents
---------------

.. py:function:: removeDisallowedFilenameChars(uncleanString)

.. py:function:: delete_recursively(path_folder, period=1, excluded_files=[])

   Delete all the files and directory inside a directory
   which have been create before a certain period
   Paramters:
       path_folder(string): path to the fomlder to delete
       period(integer): in days: delete the file older than this period
       exluded_files(list<string>): list of files to not delete


.. py:function:: generate_pdf(template, data)

