---
layout: home
---

<div id="heading" class="nhsnotify-banner--blue">
  <div class="nhsuk-main-wrapper nhsuk-width-container">
    <div class="nhsuk-grid-row">
      <div class="nhsuk-grid-column-one-half">
        <h1 class="nhsuk-heading-l">{{ site.data.home.contact.heading }}</h1>
        <p>
          {{ site.data.home.contact.description }}
        </p>
      </div>
     <div class="nhsuk-grid-column-one-half">
        {% include components/image.html src=site.data.home.contact.image alt=site.data.home.contact.image_alt class="nhsnotify-image" %}
      </div>
    </div>
  </div>
</div>

 <div class="nhsuk-width-container nhsuk-main-wrapper">
  {% include construction.html %}
</div>

<div id="benefits" class="nhsnotify-banner--white">
  <div class="nhsuk-width-container nhsuk-main-wrapper">
    <div class="nhsuk-grid-row">
      {% for item in site.data.contact.benefits %}
      <div class="nhsuk-grid-column-one-third">
        <h2 class="nhsuk-heading-m">{{ item.heading }}</h2>
        <p>{{ item.description }}</p>
      </div>
      {% endfor %}
    </div>
  </div>
</div>
