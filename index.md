---
layout: home
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

<!-- HOW IT WORKS -->
<div id="how-it-works">
  <div class="nhsuk-width-container nhsuk-main-wrapper">

{% include saf.html %}

{% include saf_dimensions.html %}
  </div>
</div>

