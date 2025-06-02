---
layout: home
nav_order: 0.1

---

<div id="heading" class="nhsnotify-banner--blue">
  <div class="nhsuk-main-wrapper nhsuk-width-container">
    <div class="nhsuk-grid-row">
      <div class="nhsuk-grid-column-one-half">
        <h1 class="nhsuk-heading-l">{{ site.data.home.heading.heading }}</h1>
        <p>
          {{ site.data.home.heading.description }}
        </p>
      </div>
      <div class="nhsuk-grid-column-one-half">
        {% include components/image.html src=site.data.home.heading.image alt=site.data.home.heading.image_alt class="nhsnotify-image" %}
      </div>
    </div>
  </div>
</div>

<div id="benefits" class="nhsnotify-banner--white">
  <div class="nhsuk-width-container nhsuk-main-wrapper">
    <div class="nhsuk-grid-row">
      {% for item in site.data.home.benefits %}
      <div class="nhsuk-grid-column-one-third">
        <h2 class="nhsuk-heading-m">{{ item.heading }}</h2>
        <p>{{ item.description }}</p>
      </div>
      {% endfor %}
    </div>
  </div>
</div>

<!-- HOW IT WORKS -->
<div id="how-it-works">
  <div class="nhsuk-width-container nhsuk-main-wrapper">
    <h2>How it works</h2>
    {% include components/styled-list.html data=site.data.home.how-it-works %}
  </div>
</div>


<!-- HOW IT WORKS -->
<div id="how-it-works">
  <div class="nhsuk-width-container nhsuk-main-wrapper">

<h2><a href="{{'safs/' | relative_url}}"> Framework Requirements</a></h2>
{% include saf.html %}

<h2><a href="{{'saf_dimensions/' | relative_url}}"> Framework Dimensions</a></h2>
{% include saf_dimensions.html %}

{%- include prev_next/prev_next.md -%}
  </div>
</div>

