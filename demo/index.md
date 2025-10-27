---
page-title: "KODAQS Toolbox"
title-block-banner: false
listing:
  - id: data-types-listing
    template: gallery/ejs/tiles.ejs
    contents: gallery/data-types/listing-contents-data-types.yml
  - id: error-sources-listing
    template: gallery/ejs/tiles.ejs
    contents: gallery/error-sources/listing-contents-error-sources.yml
comments: false
tags: ["markdown", "home", "andrew"]
---

::: {.column-screen}
```{=html}
<style>
  .image-container {
    width: 100%;
    height: 600px;
    overflow: hidden;
    position: relative;
  }
  .image-container img {
    width: 100%;
    height: auto;
    position: relative;
    top: -10%;
  }
  .white {
    background-color: rgba(255, 255, 255, 0.75);
  }
  .white p{
    color: black;
  }
</style>

<div id="carouselExampleCaptions" class="carousel slide" data-bs-ride="carousel">
  <div class="carousel-indicators">
    <button type="button" data-bs-target="#carouselExampleCaptions" data-bs-slide-to="0" class="active" aria-current="true" aria-label="Slide 1"></button>
    <button type="button" data-bs-target="#carouselExampleCaptions" data-bs-slide-to="1" aria-label="Slide 2"></button>
    <button type="button" data-bs-target="#carouselExampleCaptions" data-bs-slide-to="2" aria-label="Slide 3"></button>
  </div>
  <div class="carousel-inner">
    <div class="carousel-item active">
      <div class="image-container">
        <img src="static/AdobeStock_679112101.jpeg" alt="">
      </div>
      <div class="carousel-caption d-none d-md-block white">
        <h3>Master Data Quality Assessment with the KODAQS Toolbox</h3>
        <p> Equip your research with tools to assess and improve data quality and ensure the validity of your findings.</p>
      </div>
    </div>
    <div class="carousel-item">
      <div class="image-container">
        <img src="static/AdobeStock_790258449.jpeg" alt="">
      </div>

      <div class="carousel-caption d-none d-md-block white">
        <h3>Make Use of Learning Resources</h3>
        <p>Access the KODAQS Toolbox for practical coding examples of key quality indicators and step-by-step tutorials.</p>
      </div>
    </div>
    <div class="carousel-item">
      <div class="image-container">
        <img src="static/AdobeStock_941281453.jpeg" alt="">
      </div>

      <div class="carousel-caption d-none d-md-block  white">
        <h3>Tailored Insights for Diverse Data Types</h3>
        <p>Navigate the unique data quality challenges of survey, digital behavioral, and linked data with applied data quality assessments.</p>
      </div>
    </div>
  </div>
  <button class="carousel-control-prev" type="button" data-bs-target="#carouselExampleCaptions" data-bs-slide="prev">
    <span class="carousel-control-prev-icon" aria-hidden="true"></span>
    <span class="visually-hidden">Previous</span>
  </button>
  <button class="carousel-control-next" type="button" data-bs-target="#carouselExampleCaptions" data-bs-slide="next">
    <span class="carousel-control-next-icon" aria-hidden="true"></span>
    <span class="visually-hidden">Next</span>
  </button>
</div>
```
:::

The **KODAQS Data Quality Toolbox** is an educational resource from the _Competence Center for Data Quality (KODAQS)_, aimed at assisting researchers in developing skills for data quality assessment. It provides tutorials and practical coding examples of key quality indicators to evaluate data across various types—survey, digital behavioral, and linked data—focusing on improving validity and ensuring unbiased research outcomes. Whether handling survey data, digital behavioral data, or linked data, the KODAQS Toolbox guides users in data quality assessments tailored to diverse research interests.

Tools are categorized by **Error Source** or **Data Type**.

<h1>Error Sources</h1>

In social science data, error sources can impact the reliability and validity of research findings. Biases and inaccuracies—whether in data collection, measurement, sampling—can distort insights and reduce generalizability. Addressing these errors is essential to maintain the integrity of data analysis and ensure meaningful interpretations of social behaviors and trends

:::{#error-sources-listing}
:::

<h1>Data Types</h1>

In social science research, data capture essential information about behaviors, attitudes, and demographics, providing the basis for analyzing social patterns and relationships. The different data types—whether self-reported, observed, or combined from multiple sources—enable a comprehensive understanding of complex social dynamics and support a wide range of research questions.

:::{#data-types-listing}
:::

