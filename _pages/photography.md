---
layout: page
title: photography
permalink: /photography/
description: A collection of moments through my lens.
nav: true
nav_order: 4
---

<style>
  .photo-album {
    margin-bottom: 3.5rem;
  }

  .photo-album__header {
    margin-bottom: 1.25rem;
  }

  .photo-album__header h2 {
    margin-bottom: 0.25rem;
  }

  .photo-album__meta {
    color: var(--global-text-color-light);
    margin-bottom: 0.5rem;
  }

  .photo-grid {
    column-count: 3;
    column-gap: 1rem;
  }

  .photo-grid figure {
    break-inside: avoid;
    margin: 0 0 1rem;
  }

  .photo-grid a {
    display: block;
    overflow: hidden;
    border-radius: 0.5rem;
    background: var(--global-card-bg-color);
  }

  .photo-grid img {
    display: block;
    width: 100%;
    height: auto;
    transition:
      transform 0.25s ease,
      opacity 0.25s ease;
  }

  .photo-grid a:hover img {
    opacity: 0.94;
    transform: scale(1.015);
  }

  .photo-grid figcaption {
    color: var(--global-text-color-light);
    font-size: 0.875rem;
    margin-top: 0.4rem;
  }

  .photo-pagination {
    align-items: center;
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    justify-content: center;
    margin-top: 1rem;
  }

  .photo-pagination[hidden] {
    display: none;
  }

  .photo-pagination__pages {
    display: flex;
    flex-wrap: wrap;
    gap: 0.35rem;
  }

  .photo-pagination button {
    background: transparent;
    border: 1px solid var(--global-theme-color);
    border-radius: 0.35rem;
    color: var(--global-theme-color);
    min-width: 2.25rem;
    padding: 0.35rem 0.65rem;
  }

  .photo-pagination button:hover,
  .photo-pagination button[aria-current="page"] {
    background: var(--global-theme-color);
    color: var(--global-bg-color);
  }

  .photo-pagination button:disabled {
    cursor: not-allowed;
    opacity: 0.45;
  }

  .photo-pagination__ellipsis {
    align-self: center;
    padding: 0 0.15rem;
  }

  @media (max-width: 991px) {
    .photo-grid {
      column-count: 2;
    }
  }

  @media (max-width: 575px) {
    .photo-grid {
      column-count: 1;
    }
  }
</style>

{% assign albums = site.data.photography.albums %}
{% assign photos_per_page = site.data.photography.photos_per_page | default: 9 %}
{% assign photo_index = 0 %}

{% if albums and albums.size > 0 %}
<div data-photo-gallery data-page-size="{{ photos_per_page }}">
{% for album in albums %}
<section class="photo-album" data-photo-album{% if photo_index >= photos_per_page %} hidden{% endif %}>
<header class="photo-album__header">
<h2>{{ album.title }}</h2>
{% if album.date or album.location %}
<div class="photo-album__meta">
{{ album.date }}{% if album.date and album.location %} &middot; {% endif %}{{ album.location }}
</div>
{% endif %}
{% if album.description %}<p>{{ album.description }}</p>{% endif %}
</header>

<div class="photo-grid">
{% for photo in album.photos %}
<figure data-photo-index="{{ photo_index }}"{% if photo_index >= photos_per_page %} hidden{% endif %}>
{% assign thumb_800 = photo.image | replace_first: '/assets/img/photography/', '/assets/img/photography/thumbnails/800/' | replace: '.JPEG', '.webp' | replace: '.JPG', '.webp' | replace: '.jpeg', '.webp' | replace: '.jpg', '.webp' %}
{% assign thumb_1400 = photo.image | replace_first: '/assets/img/photography/', '/assets/img/photography/thumbnails/1400/' | replace: '.JPEG', '.webp' | replace: '.JPG', '.webp' | replace: '.jpeg', '.webp' | replace: '.jpg', '.webp' %}
<a href="{{ photo.image | relative_url }}" target="_blank" rel="noopener">
<img
  src="{{ thumb_800 | relative_url }}"
  srcset="{{ thumb_800 | relative_url }} 800w, {{ thumb_1400 | relative_url }} 1400w"
  sizes="(max-width: 575px) 100vw, (max-width: 991px) 50vw, 33vw"
  alt="{{ photo.alt | default: album.title }}"
  loading="lazy"
  decoding="async"
>
</a>
{% if photo.caption %}<figcaption>{{ photo.caption }}</figcaption>{% endif %}
</figure>
{% assign photo_index = photo_index | plus: 1 %}
{% endfor %}
</div>
</section>
{% endfor %}
</div>

<nav class="photo-pagination" data-photo-pagination aria-label="Photography pages" hidden>
<button type="button" data-photo-prev aria-label="Previous photography page">&larr; Previous</button>
<div class="photo-pagination__pages" data-photo-pages></div>
<button type="button" data-photo-next aria-label="Next photography page">Next &rarr;</button>
</nav>

<noscript>
<style>
  [data-photo-album][hidden],
  [data-photo-index][hidden] {
    display: block !important;
  }
</style>
</noscript>
{% else %}
<p>Photos will be added soon.</p>
{% endif %}

<script>
  document.addEventListener("DOMContentLoaded", () => {
    const gallery = document.querySelector("[data-photo-gallery]");
    const pagination = document.querySelector("[data-photo-pagination]");

    if (!gallery || !pagination) return;

    const photos = [...gallery.querySelectorAll("[data-photo-index]")];
    const albums = [...gallery.querySelectorAll("[data-photo-album]")];
    const pageSize = Number.parseInt(gallery.dataset.pageSize, 10) || 9;
    const totalPages = Math.ceil(photos.length / pageSize);
    const previousButton = pagination.querySelector("[data-photo-prev]");
    const nextButton = pagination.querySelector("[data-photo-next]");
    const pageButtons = pagination.querySelector("[data-photo-pages]");

    if (photos.length === 0) return;

    const pageFromUrl = () => {
      const requestedPage = Number.parseInt(new URL(window.location.href).searchParams.get("page"), 10);
      return Number.isFinite(requestedPage) ? Math.min(Math.max(requestedPage, 1), totalPages) : 1;
    };

    const updateUrl = (page) => {
      const url = new URL(window.location.href);
      if (page === 1) url.searchParams.delete("page");
      else url.searchParams.set("page", page);
      window.history.pushState({ photoPage: page }, "", url);
    };

    const createPageButton = (page, currentPage) => {
      const button = document.createElement("button");
      button.type = "button";
      button.textContent = page;
      button.setAttribute("aria-label", `Photography page ${page}`);
      if (page === currentPage) button.setAttribute("aria-current", "page");
      button.addEventListener("click", () => showPage(page, true, true));
      return button;
    };

    const renderPageButtons = (currentPage) => {
      pageButtons.replaceChildren();
      const visiblePages = new Set([1, totalPages, currentPage - 1, currentPage, currentPage + 1]);
      const pages = [...visiblePages].filter((page) => page >= 1 && page <= totalPages).sort((a, b) => a - b);

      let previousPage = 0;
      pages.forEach((page) => {
        if (previousPage && page - previousPage > 1) {
          const ellipsis = document.createElement("span");
          ellipsis.className = "photo-pagination__ellipsis";
          ellipsis.textContent = "\u2026";
          ellipsis.setAttribute("aria-hidden", "true");
          pageButtons.append(ellipsis);
        }
        pageButtons.append(createPageButton(page, currentPage));
        previousPage = page;
      });
    };

    function showPage(requestedPage, changeUrl = false, scrollToGallery = false) {
      const currentPage = Math.min(Math.max(requestedPage, 1), totalPages);
      const firstPhoto = (currentPage - 1) * pageSize;
      const lastPhoto = firstPhoto + pageSize;

      photos.forEach((photo, index) => {
        photo.hidden = index < firstPhoto || index >= lastPhoto;
      });
      albums.forEach((album) => {
        album.hidden = !album.querySelector("[data-photo-index]:not([hidden])");
      });

      previousButton.disabled = currentPage === 1;
      nextButton.disabled = currentPage === totalPages;
      renderPageButtons(currentPage);
      if (changeUrl) updateUrl(currentPage);
      if (scrollToGallery) gallery.scrollIntoView({ behavior: "smooth", block: "start" });
    }

    previousButton.addEventListener("click", () => showPage(pageFromUrl() - 1, true, true));
    nextButton.addEventListener("click", () => showPage(pageFromUrl() + 1, true, true));
    window.addEventListener("popstate", () => showPage(pageFromUrl()));

    pagination.hidden = totalPages <= 1;
    showPage(pageFromUrl());
  });
</script>
