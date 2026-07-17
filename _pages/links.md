---
layout: page
title: links
permalink: /links/
description: People and pages worth visiting.
nav: true
nav_order: 5
---

<style>
  .links-grid {
    display: grid;
    gap: 1.25rem;
    grid-template-columns: repeat(auto-fit, minmax(150px, 180px));
    justify-content: center;
  }

  .link-card {
    background: var(--global-card-bg-color);
    border: 1px solid var(--global-divider-color);
    border-radius: 0.75rem;
    color: var(--global-text-color);
    display: block;
    overflow: hidden;
    text-decoration: none;
    transition:
      box-shadow 0.2s ease,
      transform 0.2s ease;
  }

  .link-card:hover {
    box-shadow: 0 0.5rem 1.25rem rgba(0, 0, 0, 0.12);
    color: var(--global-theme-color);
    text-decoration: none;
    transform: translateY(-3px);
  }

  .link-card img {
    aspect-ratio: 1 / 1;
    display: block;
    object-fit: cover;
    width: 100%;
  }

  .link-card-name {
    font-size: 1rem;
    font-weight: 600;
    margin: 0;
    padding: 0.8rem 0.75rem;
    text-align: center;
  }
</style>

{% if site.data.related_links and site.data.related_links.size > 0 %}
<div class="links-grid">
{% for link in site.data.related_links %}
<a class="link-card" href="{{ link.url }}" target="_blank" rel="external noopener noreferrer">
<img src="{{ link.image | relative_url }}" alt="{{ link.alt | default: link.name }}" loading="lazy">
<p class="link-card-name">{{ link.name }}</p>
</a>
{% endfor %}
</div>
{% else %}
<p>No links have been added yet.</p>
{% endif %}
