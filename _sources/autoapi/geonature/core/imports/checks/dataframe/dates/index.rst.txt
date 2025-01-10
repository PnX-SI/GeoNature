geonature.core.imports.checks.dataframe.dates
=============================================

.. py:module:: geonature.core.imports.checks.dataframe.dates


Functions
---------

.. autoapisummary::

   geonature.core.imports.checks.dataframe.dates.concat_dates


Module Contents
---------------

.. py:function:: concat_dates(df: pandas.DataFrame, datetime_min_col: str, datetime_max_col: str, date_min_col: str, date_max_col: str = None, hour_min_col: str = None, hour_max_col: str = None)

   Concatenates date and time columns to form datetime columns.

   Parameters
   ----------
   df : pandas.DataFrame
       The input DataFrame.
   datetime_min_col : str
       The column name for the minimum datetime.
   datetime_max_col : str
       The column name for the maximum datetime.
   date_min_col : str
       The column name for the minimum date.
   date_max_col : str, optional
       The column name for the maximum date.
   hour_min_col : str, optional
       The column name for the minimum hour.
   hour_max_col : str, optional
       The column name for the maximum hour.



