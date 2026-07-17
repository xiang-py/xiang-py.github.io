---
layout: about
title: about
permalink: /
subtitle: 向 平宇

profile:
  align: right
  image: me.jpg
  image_circular: false # crops the image to make it circular
  more_info: >
    Taken in Hallstatt,
    Austria, in 2026.


selected_papers: true # includes a list of papers marked as "selected={true}"
social: true # includes social icons at the bottom of the page

announcements:
  enabled: true # includes a list of news items
  scrollable: true # adds a vertical scroll bar if there are more than 3 news items
  limit: 5 # leave blank to include all the news in the `_news` folder

latest_posts:
  enabled: false
  scrollable: true # adds a vertical scroll bar if there are more than 3 new posts items
  limit: 3 # leave blank to include all the blog posts
---

<style>
  @media (min-width: 576px) {
    .profile {
      width: 22%;
    }
  }

  .social .contact-icons {
    align-items: center;
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
  }

</style>

I am a Ph.D. candidate in Robotics at Zhejiang University, advised by [Prof. Haojian Lu](https://scholar.google.com/citations?user=dNAbVgIAAAAJ&hl). My research focuses on magnetic sensing and localization, medical robotics, and intelligent robotic systems.

I am particularly interested in developing flexible, reconfigurable, and uncertainty-aware sensing technologies for robotic perception and interaction in complex environments. To date, these efforts have led to publications in journals and proceedings including ***Nature Sensors***, ***IEEE T-RO***, ***IEEE T-ASE***, ***ICRA*** and ***IROS***. My current work explores magnetic tracking, continuum robot shape sensing, and human–robot interaction, with applications in minimally invasive diagnosis and intervention.

My long-term goal is to develop intelligent robotic systems that are clinically meaningful.

Feel free to reach out for research collaboration and intellectual exchange! 😀



<script>
  document.addEventListener("DOMContentLoaded", function () {
    const socialIcons = document.querySelector(".social .contact-icons");
    if (!socialIcons) return;

    const isLocalPreview = ["localhost", "127.0.0.1"].includes(window.location.hostname);
    const counterPath = isLocalPreview ? "xiang-py.github.io-local-preview" : "xiang-py.github.io";

    const counterLink = document.createElement("a");
    counterLink.id = "visitor-counter";
    counterLink.href = `https://hits.sh/${counterPath}/`;
    counterLink.title = "Website visitors";
    counterLink.setAttribute("aria-label", "View website visit statistics");

    const counterBadge = document.createElement("img");
    counterBadge.src = `https://hits.sh/${counterPath}.svg?style=flat-square&label=visitors&color=0d6efd&labelColor=555`;
    counterBadge.alt = "Website visitor count";
    counterBadge.loading = "lazy";
    counterBadge.style.cssText = "width:auto;height:22px;margin:0 0 0.75rem 1rem;vertical-align:middle";

    counterLink.appendChild(counterBadge);
    socialIcons.appendChild(counterLink);
  });
</script>
