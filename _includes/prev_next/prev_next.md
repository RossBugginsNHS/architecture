
<div style="display: flex;">
    {%- include prev_next/set_prev_next.md -%}
    <div style="flex: 1; display: flex; justify-content: flex-start;">
    {% if prev_url != "" %}
    <a href="{{ prev_url }}" id="previous-page">Previous: {{prev_name}}</a>
    {% endif %}
    </div>
    <div style="flex: 1; display: flex; justify-content: center;">
    {% if site.back_to_top %}
    <a href="#top" id="back-to-top">{{ site.back_to_top_text }}</a>
    {% endif %}
    </div>
    <div style="flex: 1; display: flex; justify-content: flex-end;">
    {% if next_url != "" %}
    <a href="{{ next_url }}" id="next-page">Next: {{next_name}}</a>
    {% endif %}
    </div>
</div>