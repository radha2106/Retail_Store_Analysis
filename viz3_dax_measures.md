DEFINE
    MEASURE '_measures'[order_revenue] = CALCULATE(SUM(ft_orders[total_revenue]),ft_orders[order_status]="Completed")

    MEASURE '_measures'[app_revenue] = SUM(ft_apps_downloaded[app_revenue])

    MEASURE '_measures'[app_download] = COUNTROWS(ft_apps_downloaded)

    MEASURE '_measures'[lm_order_revenue] = udf_last_month_result([order_revenue],1)

    MEASURE '_measures'[last_month_app_revenue] = udf_last_month_result([app_revenue],1)

    MEASURE '_measures'[last_month_app_download] = udf_last_month_result([app_download],1)

    MEASURE '_measures'[color_app_download] = udf_last_month_color([app_download])

    MEASURE '_measures'[label_lm_title] = "monthly change:"

    MEASURE '_measures'[avg_app_download] = AVERAGEX(VALUES(dim_apps_subcategory[idx]),CALCULATE(COUNTROWS(ft_apps_downloaded)))

    MEASURE '_measures'[label_apps] = SELECTEDVALUE(dim_apps_subcategory[app_subcatg_name])& " | " & FORMAT([app_revenue],"$##,##00")

    MEASURE '_measures'[avg_app_revenue] = AVERAGE(ft_apps_downloaded[app_revenue])

    MEASURE '_measures'[app_high_rate] = CALCULATE(COUNTROWS(ft_apps_downloaded),ft_apps_downloaded[app_rate] = 5)

    MEASURE '_measures'[last_month_app_rate] = udf_last_month_result([app_high_rate],1)

    MEASURE '_measures'[color_app_rate] = udf_last_month_color([app_high_rate])

    MEASURE '_measures'[max_label_app] = udf_max_label([app_download])

    MEASURE '_measures'[label_base] = 0

    MEASURE '_measures'[last_month_avg_app_revenue] = udf_last_month_result([avg_app_revenue],1)

    MEASURE '_measures'[last_month_avg_app_download] = udf_last_month_result([avg_app_download],1)

    MEASURE '_measures'[all_revenue] = [app_revenue] + [order_revenue]

    MEASURE '_measures'[online_order_revenue] = CALCULATE(SUM(ft_orders[total_revenue]),ft_orders[order_status]="Completed",ft_orders[bougth_as]="Online")

    MEASURE '_measures'[store_order_revenue] = CALCULATE(SUM(ft_orders[total_revenue]),ft_orders[order_status]="Completed",ft_orders[bougth_as]="In-store")

    MEASURE '_measures'[lm_online_order_revenue] = udf_last_month_result([online_order_revenue],1)

    MEASURE '_measures'[lm_store_order_revenue] = udf_last_month_result([store_order_revenue],1)

    MEASURE '_measures'[online_items_returned] = CALCULATE(COUNTROWS(ft_orders),ft_orders[order_status]="Returned",ft_orders[bougth_as]="Online")

    MEASURE '_measures'[store_item_returned] = CALCULATE(COUNTROWS(ft_orders),ft_orders[order_status]="Returned",ft_orders[bougth_as]="In-store")

    MEASURE '_measures'[store_order_returned_revenue_lost] = CALCULATE(SUM(ft_orders[total_revenue]),ft_orders[order_status]="Returned",ft_orders[bougth_as]="In-store")

    MEASURE '_measures'[label_devices] = udf_bar_label(dim_device_names[item_name],[order_revenue])

    MEASURE '_measures'[ytd_order_revenue] = VAR CurrentMonth = SELECTEDVALUE(dim_calendar[months])
RETURN
    IF(
        CurrentMonth = 1, 
        BLANK(),
        TOTALYTD(SUM(ft_orders[total_revenue]),dim_calendar[dates],ft_orders[order_status]="Completed"))

    MEASURE '_measures'[online_items_orders] = CALCULATE(COUNTROWS(ft_orders),ft_orders[order_status]="Completed",ft_orders[bougth_as] = "Online")

    MEASURE '_measures'[store_items_orders] = CALCULATE(COUNTROWS(ft_orders),ft_orders[order_status]="Completed",ft_orders[bougth_as] = "In-store")

    MEASURE '_measures'[online_order_returned_revenue_lost] = CALCULATE(SUM(ft_orders[total_revenue]),ft_orders[order_status]="Returned",ft_orders[bougth_as]="Online")

    MEASURE '_measures'[last_month_online_order_items] = udf_last_month_result([online_items_orders],1)

    MEASURE '_measures'[last_month_store_order_items] = udf_last_month_result([store_items_orders],1)

    MEASURE '_measures'[label_lm_orders_items] = "last month items sold:"

    MEASURE '_measures'[label_lm_item_returned] = "items returned:"

    MEASURE '_measures'[label_revenue_returned] = "revenue returned:"

    MEASURE '_measures'[label_yearly_title] = "yearly revenue:"

    MEASURE '_measures'[visits] = COUNTROWS(ft_orders)

    MEASURE '_measures'[all_orders_completed] = CALCULATE(COUNTROWS(ft_orders),ft_orders[order_status]="Completed")

    MEASURE '_measures'[max_label_device] = udf_max_label([visits])

    MEASURE '_measures'[all_orders] = COUNTROWS(ft_orders)

    MEASURE '_measures'[label_category] = udf_bar_label(dim_device_category[category],[order_revenue])

    MEASURE '_measures'[total_customers] = CALCULATE(COUNTROWS(dim_customers),USERELATIONSHIP(dim_calendar[idx],dim_customers[created_on]))

    MEASURE '_measures'[avg_revenue] = AVERAGEX(VALUES('dim_calendar'[dates]),[all_revenue])

    MEASURE '_measures'[avg_orders] = AVERAGEX(VALUES('dim_calendar'[dates]),[all_orders_completed])

    MEASURE '_measures'[lm_revenue] = udf_last_month_result([all_revenue],1)

    MEASURE '_measures'[lm_orders_completed] = udf_last_month_result([all_orders_completed],0)

    MEASURE '_measures'[lm_customer] = udf_last_month_result([total_customers],1)

    MEASURE '_measures'[last_status_icon] = SWITCH(TRUE(),
[last_status]="Completed",[complete_button],
[last_status]="Pending",[pending_button],
[last_status]="Returned",[return_button])

    MEASURE '_measures'[items_returned] = VAR _result = [online_items_returned] + [store_item_returned]
RETURN
IF(_result=BLANK(),BLANK(),_result)

    MEASURE '_measures'[order_refund] = CALCULATE(SUM(ft_orders[total_revenue]),ft_orders[order_status]="Returned")

    MEASURE '_measures'[last_status] = VAR _last_row = 
    MAXX( ft_orders,ft_orders[row_number])

VAR _last_status = 
    MAXX(
        FILTER( ft_orders,ft_orders[row_number] = _last_row ),
        ft_orders[order_status]
    )

RETURN 
    _last_status

    MEASURE '_measures'[complete_button] = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='65' height='18'>
  <rect x='0' y='0' width='65' height='18' rx='3' fill='#65f0b9'/>
  <text x='50%' y='60%' font-family='Segoe UI' font-size='9.5' font-weight='650'
        fill='#00815d' text-anchor='middle' dominant-baseline='middle'>
    Completed</text>
</svg>"

    MEASURE '_measures'[pending_button] = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='65' height='18'>
  <rect x='0' y='0' width='65' height='18' rx='3' fill='#F1C94C'/>
  <text x='50%' y='60%' font-family='Segoe UI' font-size='9.5' font-weight='700'
        fill='#4D3A13' text-anchor='middle' dominant-baseline='middle'>
    Pending</text>
</svg>"

    MEASURE '_measures'[return_button] = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='65' height='18'>
  <rect x='0' y='0' width='65' height='18' rx='3' fill='#f2afb2'/>
  <text x='50%' y='60%' font-family='Segoe UI' font-size='9.5' font-weight='700'
        fill='#792236' text-anchor='middle' dominant-baseline='middle'>
    Returned</text>
</svg>"

    MEASURE '_measures'[product_prm_value] = SUM(ft_orders[total_revenue])

    MEASURE '_measures'[color_all_revenue] = udf_last_month_color([all_revenue])
    
    MEASURE '_measures'[color_total_customer] = udf_last_month_color([total_customers])

    MEASURE '_measures'[color_app_revenue] = udf_last_month_color([app_revenue])

    MEASURE '_measures'[color_order_revenue] = udf_last_month_color([order_revenue])

    MEASURE '_measures'[color_order_completed] = udf_last_month_color([all_orders_completed])

    MEASURE '_measures'[max_min_point_all_revenue] = udf_maxmin_point([all_revenue])

    MEASURE '_measures'[color_order_store] = udf_last_month_color([store_order_revenue])

    MEASURE '_measures'[color_order_online] = udf_last_month_color([online_order_revenue])

    MEASURE '_measures'[max_min_point_device_revenue] = udf_maxmin_point([order_revenue])

    MEASURE '_measures'[max_min_point_apps_revenue] = udf_maxmin_point([app_revenue])