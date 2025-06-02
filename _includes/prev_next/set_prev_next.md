
{%- assign site_pages_only = site.pages -%} 
{%- assign site_saf_dimensions = site.saf_dimensions -%} 
{%- assign site_safs = site.safs -%} 

{% assign site_pages = site_pages_only | concat: site_saf_dimensions | concat: site_safs %}


{%- assign query_page = page -%} 
{%- include prev_next/set_site_order.md -%} 
{%- assign page_site_order = site_order -%}

{%- assign prev_site_order = -1 -%} 
{%- assign next_site_order = 1000000000 -%} 
{%- assign prev_url = "" -%} 
{%- assign next_url = "" -%}
{%- assign prev_name = "" -%} 
{%- assign next_name = "" -%}

{%- for query_page in site_pages -%} 
{%- include prev_next/set_site_order.md -%} 
{%- if site_order < page_site_order and site_order > prev_site_order -%} 
{%- assign prev_site_order = site_order -%} 
{%- assign prev_url = query_page.url | relative_url -%}
{%- assign prev_name = query_page.title -%} 
{%- elsif site_order > page_site_order and site_order < next_site_order -%} 
{%- assign next_site_order = site_order -%} 
{%- assign next_url = query_page.url | relative_url -%} 
{%- assign next_name = query_page.title -%} 

{%- endif -%} 
{%- endfor -%}