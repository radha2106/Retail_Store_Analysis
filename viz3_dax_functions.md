DEFINE

    /// Shows only the max and min value in a bar chart
    FUNCTION udf_max_label = (_measure:MEASUREREF) =>
VAR _currentval = _measure
VAR _maxval = 
    CALCULATE(MAXX(VALUES(dim_calendar[days_name]),_measure),ALLSELECTED())
VAR _minval = 
    CALCULATE(MINX(VALUES(dim_calendar[days_name]),_measure),ALLSELECTED())
RETURN
SWITCH(TRUE,
_currentval = _maxval, _maxval,
_currentval = _minval, _minval,
"")

    /// Show max and min value point in a line chart
    FUNCTION udf_maxmin_point = (_measure:MEASUREREF) =>
VAR var_maxvalue =
    CALCULATE(MAXX(VALUES(dim_calendar[days]),_measure),ALLSELECTED())

VAR var_minvalue = 
    CALCULATE(MINX(VALUES(dim_calendar[days]),_measure),ALLSELECTED())

RETURN
//Compare value to get only max and min day value revenue
SWITCH(TRUE(),
    _measure = var_maxvalue,"#706BF8",
    _measure = var_minvalue,"#706BF8")


    /// Get the alst month result, total or percentage
    FUNCTION udf_last_month_result = (_measure:MEASUREREF,_option:INT64) =>

VAR _first_month = SELECTEDVALUE(dim_calendar[months])

VAR _last_month = 
    IF(
        _first_month = 1, 
        BLANK(),
        CALCULATE(_measure, DATEADD('dim_calendar'[dates], -1, MONTH))
    )

VAR _growth_pct = DIVIDE(_measure-_last_month,_last_month)
VAR _growth_abs = SWITCH(TRUE(),_first_month=1,BLANK(),_measure-_last_month)

VAR _pct = "+0.0%;-0.0%;0%"
VAR _abs = "+#,##;-#,##;0"

VAR _pct_format = FORMAT(_growth_pct,_pct)
VAR _abs_format = FORMAT(_growth_abs,_abs)

VAR _up= UNICHAR(129053)
VAR _down=UNICHAR(129055)

VAR _total_icons = SWITCH(TRUE(),_growth_abs > 0 , _abs_format & _up, _growth_abs < 0 , _abs_format & _down)
VAR _pct_icons = SWITCH(TRUE(),_growth_pct > 0 , _pct_format & _up, _growth_pct < 0 , _pct_format & _down)

RETURN
SWITCH(TRUE(),
_option = 0, _total_icons,
_option = 1, _pct_icons)

    /// Show category and measure all together
    FUNCTION udf_bar_label = (_column:COLUMNREF,_measure:MEASUREREF) =>
SELECTEDVALUE(_column)& " | " & FORMAT(_measure,"$##,##00")

    /// Format color to measure
    FUNCTION udf_last_month_color = (_measure:MEASUREREF) =>

VAR _first_month = SELECTEDVALUE(dim_calendar[months])

VAR _last_month = 
    IF(
        _first_month = 1, 
        BLANK(),
        CALCULATE(_measure, DATEADD('dim_calendar'[dates], -1, MONTH))
    )

VAR _growth=DIVIDE(_measure-_last_month,_last_month)

RETURN
    SWITCH(TRUE(),
        _last_month=BLANK(),"#8A8E93",//"B"
		_growth>0,"#0f6e56",//"G"
        _growth<0,"#a32d2d")//"R"