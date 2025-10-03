---
title: Improvement Suggestions
nav_order: 1.7
parent: SAF Introduction
description: Consolidated list of structured suggestions for SAF content, taxonomy, automation and consistency improvements.
---

{%- comment -%}
	Data structure explanation:
	File path: _data/suggestions/suggestions.yml
	Access pattern: site.data.<folder>.<filename>
	Inside the file we have a top-level key 'suggestions:' which holds the array.
	Therefore the actual array is: site.data.suggestions.suggestions.suggestions
	(folder)        (file)       (key)
	We keep a fallback so if the YAML is later flattened (list at root) the page still works.
{%- endcomment -%}
{% assign suggestions_container = site.data.suggestions.suggestions %}
{% if suggestions_container == nil or suggestions_container == empty %}
	{% comment %}Try flattened variant (file: _data/suggestions.yml){% endcomment %}
	{% assign suggestions_container = site.data.suggestions %}
{% endif %}
{% if suggestions_container.suggestions %}
	{% assign suggestions = suggestions_container.suggestions %}
{% else %}
	{% assign suggestions = suggestions_container %}
{% endif %}
{% if suggestions == nil %}
> No suggestions data found (expected in `_data/suggestions/suggestions.yml`).
{% endif %}

{% comment %}
	Helper: build SAF link for a given ID based on its leading letters.
	Directory mapping (prefix -> dir): D->d, DM->dm, NF->nf, RU->ru, S->s, SD->sd, T->t
{% endcomment %}
{% capture saf_link_snippet %}
	{% assign saf_id = id %}
	{% assign first2 = saf_id | slice: 0, 2 %}
	{% assign first1 = saf_id | slice: 0, 1 %}
	{% assign dir = '' %}
	{% if first2 == 'DM' %}{% assign dir = 'dm' %}
	{% elsif first2 == 'NF' %}{% assign dir = 'nf' %}
	{% elsif first2 == 'RU' %}{% assign dir = 'ru' %}
	{% elsif first2 == 'SD' %}{% assign dir = 'sd' %}
	{% elsif first2 == 'DM' %}{% assign dir = 'dm' %}
	{% elsif first1 == 'D' %}{% assign dir = 'd' %}
	{% elsif first1 == 'S' %}{% assign dir = 's' %}
	{% elsif first1 == 'T' %}{% assign dir = 't' %}
	{% endif %}
	{% if dir != '' %}
		<a href="/safs/{{ dir }}/{{ saf_id | downcase }}.html">{{ saf_id }}</a>
	{% else %}
		{{ saf_id }}
	{% endif %}
{% endcapture %}

<style>
	/* Lightweight table styling (scoped) */
	.suggestions-table { width: 100%; border-collapse: collapse; font-size: 0.9rem; }
	.suggestions-table th, .suggestions-table td { border: 1px solid #ddd; padding: 0.5rem; vertical-align: top; }
	.suggestions-table th { background:#f5f5f5; text-align:left; }
	.suggestions-table tr.priority-P1 { border-left:4px solid #b30000; }
	.suggestions-table tr.priority-P2 { border-left:4px solid #d28700; }
	.suggestions-table tr.priority-P3 { border-left:4px solid #707070; }
	.nowrap { white-space: nowrap; }
	.pill { display:inline-block; padding:0 0.4em; border-radius:0.8em; background:#eef; margin:0 0.15em 0.15em 0; }
	.cat-duplication { background:#ffe5e5; }
	.cat-automation { background:#e5f6ff; }
	.cat-consistency { background:#f1f5ff; }
	.cat-taxonomy { background:#f5ffe5; }
	.cat-metadata { background:#fff4e5; }
	.cat-governance { background:#f0e5ff; }
	.cat-clarity { background:#e5fff8; }
	.cat-content-gap { background:#fffbe5; }
	details.summary-block { margin-bottom:1rem; }
	.legend span { margin-right:1rem; }
	.status-planned { background:#e8e8e8; }
	.dep a { font-size:0.8em; }
	.small { font-size:0.75rem; color:#555; }
	.filter-note { font-size:0.8rem; color:#555; margin-bottom:0.75rem; }
</style>

## Overview

This page lists structured improvement suggestions for the Solution Architecture Framework (SAF). They are sourced from the data file `_data/suggestions/suggestions.yml` and intended to guide content refactors, automation enablers and consistency improvements. Each suggestion has an identifier, category, impacted SAF references, rationale, impact, indicative effort and priority.

{% assign count_total = suggestions | size %}
{% assign p1 = 0 %}{% assign p2 = 0 %}{% assign p3 = 0 %}
{% for s in suggestions %}
	{% if s.priority == 'P1' %}{% assign p1 = p1 | plus: 1 %}{% endif %}
	{% if s.priority == 'P2' %}{% assign p2 = p2 | plus: 1 %}{% endif %}
	{% if s.priority == 'P3' %}{% assign p3 = p3 | plus: 1 %}{% endif %}
{% endfor %}

**Totals:** {{ count_total }} suggestions (P1: {{ p1 }}, P2: {{ p2 }}, P3: {{ p3 }})

### Legend

<div class="legend small">
	<span><strong>Priority:</strong> P1 (higher value / sooner), P2, P3 (later / opportunistic)</span>
	<span><strong>Effort:</strong> S (Small), M (Medium), L (Larger)</span>
	<span><strong>Status:</strong> planned = not yet actioned</span>
</div>

### Category Breakdown

{% comment %}Build category counts manually{% endcomment %}
{% comment %}Simpler category counting logic{% endcomment %}
{% assign categories_csv = '' %}
{% for s in suggestions %}
	{% unless categories_csv contains s.category %}
		{% assign categories_csv = categories_csv | append: s.category | append: ',' %}
	{% endunless %}
{% endfor %}
{% assign categories = categories_csv | split: ',' | sort %}
<ul>
	{% for c in categories %}
		{% if c != '' %}
			{% assign cat_count = 0 %}
			{% for s in suggestions %}{% if s.category == c %}{% assign cat_count = cat_count | plus: 1 %}{% endif %}{% endfor %}
			<li><code>{{ c }}</code>: {{ cat_count }}</li>
		{% endif %}
	{% endfor %}
</ul>

<p class="filter-note">(You can use your browser find (Ctrl/Cmd+F) for an ID, category or SAF reference.)</p>

## Suggestions List

{% comment %}Simple priority ordering: output P1 then P2 then P3 preserving original file order{% endcomment %}
{% comment %}Build ordered list by priority groups preserving input order{% endcomment %}
{% assign ordered_ids = '' %}
{% for s in suggestions %}{% if s.priority == 'P1' %}{% assign ordered_ids = ordered_ids | append: s.id | append: ',' %}{% endif %}{% endfor %}
{% for s in suggestions %}{% if s.priority == 'P2' %}{% assign ordered_ids = ordered_ids | append: s.id | append: ',' %}{% endif %}{% endfor %}
{% for s in suggestions %}{% if s.priority == 'P3' %}{% assign ordered_ids = ordered_ids | append: s.id | append: ',' %}{% endif %}{% endfor %}
{% assign ordered_ids = ordered_ids | split: ',' %}
<table class="suggestions-table">
	<thead>
		<tr>
			<th>ID</th>
			<th>Category</th>
			<th>SAFs</th>
			<th>Suggested Change & Rationale</th>
			<th>Impact</th>
			<th class="nowrap">Effort</th>
			<th class="nowrap">Priority</th>
			<th>Dependencies</th>
			<th>Status</th>
		</tr>
	</thead>
	<tbody>
			{% for oid in ordered_ids %}
			{% if oid == '' %}{% continue %}{% endif %}
			{% assign s = nil %}
			{% for candidate in suggestions %}{% if candidate.id == oid %}{% assign s = candidate %}{% break %}{% endif %}{% endfor %}
			{% if s == nil %}{% continue %}{% endif %}
		{% assign pr = s.priority %}
		<tr id="{{ s.id }}" class="priority-{{ pr }}">
			<td class="nowrap"><strong>{{ s.id }}</strong></td>
			<td>
				{% assign cat_class = 'cat-' | append: s.category %}
				<span class="pill {{ cat_class }}">{{ s.category }}</span>
			</td>
			<td>
				{% for rid in s.referenced_saf_ids %}
					{% comment %} Render SAF link using mapping logic {% endcomment %}
					{% assign saf_id = rid %}
					{% assign first2 = saf_id | slice: 0, 2 %}
					{% assign first1 = saf_id | slice: 0, 1 %}
					{% assign dir = '' %}
					{% if first2 == 'DM' %}{% assign dir = 'dm' %}{% elsif first2 == 'NF' %}{% assign dir = 'nf' %}{% elsif first2 == 'RU' %}{% assign dir = 'ru' %}{% elsif first2 == 'SD' %}{% assign dir = 'sd' %}{% elsif first1 == 'D' %}{% assign dir = 'd' %}{% elsif first1 == 'S' %}{% assign dir = 's' %}{% elsif first1 == 'T' %}{% assign dir = 't' %}{% endif %}
					{% if dir != '' %}<a href="{{ '/safs/' | append: dir | append: '/' | append: saf_id | downcase | append: '.html' | relative_url }}">{{ saf_id }}</a>{% else %}{{ saf_id }}{% endif %}{% unless forloop.last %}, {% endunless %}
				{% endfor %}
			</td>
			<td>
				<strong>Change:</strong> {{ s.suggested_change }}<br/>
				<strong>Rationale:</strong> {{ s.rationale }}
				{% if s.notes %}<br/><span class="small"><strong>Notes:</strong> {{ s.notes }}</span>{% endif %}
			</td>
			<td>{{ s.impact }}</td>
			<td class="nowrap">{{ s.effort }}</td>
			<td class="nowrap">{{ s.priority }}</td>
			<td class="dep">
				{% if s.dependencies and s.dependencies.size > 0 %}
					{% for dep in s.dependencies %}<a href="#{{ dep }}">{{ dep }}</a>{% unless forloop.last %}, {% endunless %}{% endfor %}
				{% else %}-{% endif %}
			</td>
			<td>
				{% assign st = s.status | default: 'planned' %}
				<span class="pill status-{{ st }}">{{ st }}</span>
			</td>
		</tr>
	{% endfor %}
	</tbody>
</table>

### Suggested Sequencing (Derived)

The following is an indicative wave plan (resolving dependencies first, grouping related automation / metadata steps):

1. Foundational deduplication & taxonomy: SUG-001, SUG-003, SUG-007
2. Quick clarity / correctness fixes (unblocked): SUG-002, SUG-017
3. Metadata & automation enablers: SUG-009 (enables SUG-021), SUG-015, SUG-016
4. Cost / value alignment: SUG-020 then dependent SUG-030
5. Broader consistency & remaining content gaps (parallel where independent)

> This ordering is advisory; adjust based on current work in flight and resource availability.

---

If you want to propose an update, add or modify entries in `_data/suggestions/suggestions.yml` via pull request. Consider grouping related proposals together for review clarity and keep rationale concise but actionable.

