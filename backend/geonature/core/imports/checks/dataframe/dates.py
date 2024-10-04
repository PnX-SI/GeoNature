def concat_dates(
    df,
    datetime_min_col,
    datetime_max_col,
    date_min_col,
    date_max_col=None,
    hour_min_col=None,
    hour_max_col=None,
):
    assert datetime_min_col
    assert datetime_max_col
    assert date_min_col  # date_min is a required field
    date_max_col = date_max_col if date_max_col else None
    hour_min_col = hour_min_col if hour_min_col else None
    hour_max_col = hour_max_col if hour_max_col else None

    date_min = df[date_min_col]

    if hour_min_col and hour_min_col in df:
        hour_min = df[hour_min_col].where(df[hour_min_col].notna(), other="00:00:00")

    if hour_min_col and hour_min_col in df:
        df[datetime_min_col] = date_min + " " + hour_min
    else:
        df[datetime_min_col] = date_min

    if date_max_col and date_max_col in df:
        date_max = df[date_max_col].where(df[date_max_col].notna(), date_min)
    else:
        date_max = date_min

    if hour_max_col and hour_max_col in df:
        if date_max_col and date_max_col in df:
            # hour max is set to hour min if date max is none (because date max will be set to date min), else 00:00:00
            if hour_min_col and hour_min_col in df:
                # if hour_max not set, use hour_min if same day (or date_max not set, so same day)
                hour_max = df[hour_max_col].where(
                    df[hour_max_col].notna(),
                    other=hour_min.where(date_min == date_max, other="00:00:00"),
                )
            else:
                hour_max = df[hour_max_col].where(df[hour_max_col].notna(), other="00:00:00")
        else:
            if hour_min_col and hour_min_col in df:
                hour_max = df[hour_max_col].where(df[hour_max_col].notna(), other=hour_min)
            else:
                hour_max = df[hour_max_col].where(df[hour_max_col].notna(), other="00:00:00")

    if hour_max_col and hour_max_col in df:
        df[datetime_max_col] = date_max + " " + hour_max
    elif hour_min_col and hour_min_col in df:
        df[datetime_max_col] = date_max + " " + hour_min
    else:
        df[datetime_max_col] = date_max

    return {datetime_min_col, datetime_max_col}
