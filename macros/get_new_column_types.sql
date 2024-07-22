{% macro get_new_column_types () %}
    {% set new_columns = [] %}
    {% set source = 'BLACKROCK.TEST.SCHEMA_DETECTION_RAW_TEST' %}
    {% set date_format_expression = 'YYYY-MM-DD' %}
    {% set date_format_expression = date_format_expression | replace('YYYY', '[0-9]{4}') | replace('MM', '[0-1][0-9]') | replace('DD', '[0-3][0-9]') %}
    {% set columns = [column.create('test_number'), column.create('test_decimal'), column.create('test_date'), column.create('test_string')] %}
    
    with base as (
        {% for column in columns %}
            select 
                '{{column.name}}' as column_name,
                case
                    when regexp_like("{{column.name}}", $${{date_format_expression}}$$) then 'date'
                    when regexp_like("{{column.name}}", $$[0-9]+\.[0-9]+$$) then 'number (38,' || max(length(split_part("{{column.name}}", '.', 2))) || ')'
                    when regexp_like("{{column.name}}", $$[0-9]+$$) then 'number (38,0)'				
                    else 'string' 
                end as column_type	
            from {{source}}
            where {{column.name}} is not null
            group by {{column.name}}
            {% if not loop.last %} union {% endif %}
        {% endfor %}
    ),
    types as (
        select
            column_name,
            column_type,
            rank() over (partition by column_name order by column_type desc) as primary_type
        from base
        group by column_type, column_name
    )
    select
        column_name,
        column_type
    from types
    where primary_type = 1;

    {% set results = run_query(sql) %}

    {% for row in results.rows %}
        {% set name = row[0] %}
        {% set data_type = row[1] %}
        {% set act_row = column.create(name, data_type) %}
        {% do  new_columns.append(act_row) %}
    {% endfor %}
    {{ return(new_columns) }}
{% endmacro %}
