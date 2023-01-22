{% macro sqlserver__create_table_as(temporary, relation, sql) -%}
   {%- set as_columnstore = config.get('as_columnstore', default=true) -%}
   {%- set query_hints = config.get('query_hints', default=None) -%}
   {% set tmp_relation = relation.incorporate(
   path={"identifier": relation.identifier.replace("#", "") ~ '_temp_view'},
   type='view')-%}
   {%- set temp_view_sql = sql.replace("'", "''") -%}

   {{ sqlserver__drop_relation_script(tmp_relation) }}

   {{ sqlserver__drop_relation_script(relation) }}

   USE [{{ relation.database }}];
   EXEC('create view {{ tmp_relation.include(database=False) }} as
    {{ temp_view_sql }}
    ');

   SELECT * INTO {{ relation }} FROM
    {{ tmp_relation }}
    {% if query_hints %}OPTION ({{ query_hints }}){% endif -%}

   {{ sqlserver__drop_relation_script(tmp_relation) }}

   {% if not temporary and as_columnstore -%}
   {{ sqlserver__create_clustered_columnstore_index(relation) }}
   {% endif %}

{% endmacro %}
