# 📋 Deployment Checklist - EmpericalPatternR Documentation

## ✅ Pre-Deployment Checklist

### Package Files

  - \[x\] Vignettes created (3 files in `vignettes/`)
  - \[x\] PKGdown configuration (`_pkgdown.yml`)
  - \[x\] Enhanced README with badges and examples
  - \[x\] DESCRIPTION updated with vignette dependencies
  - \[x\] .Rbuildignore configured
  - \[x\] Documentation site built (`docs/` folder)
  - \[x\] All function documentation complete (42 functions)
  - \[x\] Tests passing (62/62)

### Documentation Quality

  - \[x\] Getting Started vignette (beginner-friendly)
  - \[x\] Pinyon-Juniper vignette (complete workflow)
  - \[x\] Ponderosa Pine vignette (customization)
  - \[x\] Function reference organized by topic
  - \[x\] Code examples all working
  - \[x\] Cross-references in place
  - \[x\] Search index built

## 🔧 Optional Updates Before Deploy

### 1\. Update GitHub URLs (Recommended)

**File: `_pkgdown.yml`** (line 1)

``` yaml
# CURRENT:
url: https://github.com/yourusername/EmpericalPatternR

# UPDATE TO:
url: https://bi0m3trics.github.io/EmpericalPatternR
```

**File: `README.md`** (lines 3-5)

``` markdown
<!-- CURRENT: -->
[![R-CMD-check](https://github.com/yourusername/EmpericalPatternR/workflows/R-CMD-check/badge.svg)](https://github.com/yourusername/EmpericalPatternR/actions)

<!-- UPDATE TO: -->
[![R-CMD-check](https://github.com/bi0m3trics/EmpericalPatternR/workflows/R-CMD-check/badge.svg)](https://github.com/bi0m3trics/EmpericalPatternR/actions)
```

**File: `README.md`** (bottom section)

``` markdown
<!-- CURRENT: -->
- 📧 Open an issue on [GitHub](https://github.com/yourusername/EmpericalPatternR/issues)
- 📖 See [documentation](https://yourusername.github.io/EmpericalPatternR/)

<!-- UPDATE TO: -->
- 📧 Open an issue on [GitHub](https://github.com/bi0m3trics/EmpericalPatternR/issues)
- 📖 See [documentation](https://bi0m3trics.github.io/EmpericalPatternR/)
```

**File: `_pkgdown.yml`** (bottom section)

``` yaml
# CURRENT:
authors:
  Your Name:
    href: https://github.com/yourusername

# UPDATE TO:
authors:
  Andrew Sánchez Meador:
    href: https://github.com/bi0m3trics
```

### 2\. Create Package Logo (Optional)

If you want a hex sticker logo:

``` r
# Install hexSticker package
install.packages("hexSticker")

# Create logo (customize as desired)
library(hexSticker)
sticker(
  subplot = "path/to/image.png",  # Or use ggplot
  package = "EmpericalPatternR",
  p_size = 8,
  s_width = 1.2,
  s_height = 1,
  h_fill = "#2c5f2d",      # Forest green
  h_color = "#97bc62",     # Light green
  filename = "man/figures/logo.png"
)
```

Then rebuild site:

``` r
source("build_pkgdown.R")
```

### 3\. Add Accessibility Labels (Optional)

**File: `_pkgdown.yml`** (navbar section)

``` yaml
# CURRENT:
    home:
      icon: fa-home fa-lg
      href: index.html

# UPDATE TO:
    home:
      icon: fa-home fa-lg
      href: index.html
      aria-label: "Home"
```

## 🚀 Deployment Steps

### Step 1: Commit All Changes

``` bash
cd "d:\OneDrive - Northern Arizona University\GitHubRepos\EmpericalPatternR"
git add .
git commit -m "Add comprehensive pkgdown documentation with three vignettes

- Created getting-started vignette (installation, quick start, basics)
- Created pinyon-juniper vignette (complete P-J workflow)
- Created ponderosa-pine vignette (custom configurations)
- Built pkgdown site with organized function reference
- Enhanced README with badges, examples, and documentation links
- Added knitr and rmarkdown dependencies for vignettes
- Organized functions into 9 logical topic groups
"
```

### Step 2: Push to GitHub

``` bash
git push origin main
```

### Step 3: Enable GitHub Pages

1.  Go to:
    <https://github.com/bi0m3trics/EmpericalPatternR/settings/pages>

2.  Under “Build and deployment”:
    
      - **Source**: Deploy from a branch
      - **Branch**: main (or master if that’s your default)
      - **Folder**: /docs

3.  Click **Save**

4.  Wait 2-3 minutes for deployment

5.  Visit: <https://bi0m3trics.github.io/EmpericalPatternR/>

### Step 4: Verify Deployment

Check that all these pages work: - \[ \] Home:
<https://bi0m3trics.github.io/EmpericalPatternR/> - \[ \] Getting
Started:
<https://bi0m3trics.github.io/EmpericalPatternR/articles/getting-started.html>
- \[ \] Pinyon-Juniper:
<https://bi0m3trics.github.io/EmpericalPatternR/articles/pinyon-juniper.html>
- \[ \] Ponderosa Pine:
<https://bi0m3trics.github.io/EmpericalPatternR/articles/ponderosa-pine.html>
- \[ \] Function Reference:
<https://bi0m3trics.github.io/EmpericalPatternR/reference/index.html> -
\[ \] Search works (top right corner)

## 📊 Post-Deployment

### Update README Badge (Optional)

Once site is live, you can add a docs
badge:

``` markdown
[![pkgdown](https://img.shields.io/badge/docs-pkgdown-blue.svg)](https://bi0m3trics.github.io/EmpericalPatternR/)
```

Add this near the other badges in README.md

### Share the Documentation

Update your package README to prominently
feature:

``` markdown
📖 **[Read the Documentation](https://bi0m3trics.github.io/EmpericalPatternR/)**
```

### Announce to Users

Template message:

    EmpericalPatternR now has comprehensive documentation!
    
    📚 Three detailed vignettes:
    - Getting Started (for beginners)
    - Pinyon-Juniper Workflow (complete example)
    - Ponderosa Pine Customization (advanced)
    
    🔍 Searchable function reference with 42 documented functions
    
    🌐 Visit: https://bi0m3trics.github.io/EmpericalPatternR/
    
    All code examples are copy-paste ready. Everything you need to go from
    installation to running your own simulations!

## 🔄 Maintaining Documentation

### When You Update Functions

1.  Update roxygen comments in R files
2.  Run: `devtools::document()`
3.  Run: `source("build_pkgdown.R")`
4.  Commit and push

### When You Update Vignettes

1.  Edit .Rmd files in `vignettes/`
2.  Run: `source("build_pkgdown.R")`
3.  Commit and push

### Auto-Rebuild with GitHub Actions (Advanced)

Create `.github/workflows/pkgdown.yaml`:

``` yaml
on:
  push:
    branches: [main, master]

name: pkgdown

jobs:
  pkgdown:
    runs-on: ubuntu-latest
    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - uses: actions/checkout@v2
      - uses: r-lib/actions/setup-r@v2
      - uses: r-lib/actions/setup-pandoc@v2
      - name: Install dependencies
        run: |
          install.packages(c("remotes", "pkgdown"))
          remotes::install_deps(dependencies = TRUE)
        shell: Rscript {0}
      - name: Build site
        run: pkgdown::build_site()
        shell: Rscript {0}
      - name: Deploy to GitHub pages
        uses: JamesIves/github-pages-deploy-action@4.1.5
        with:
          branch: gh-pages
          folder: docs
```

This auto-rebuilds docs on every push.

## ✅ Final Checklist

Before announcing your documentation:

  - \[ \] All URLs updated (no “yourusername” placeholders)
  - \[ \] Site deployed and accessible
  - \[ \] All three vignettes render correctly
  - \[ \] Search functionality works
  - \[ \] Function reference organized properly
  - \[ \] Examples run without errors
  - \[ \] Mobile view looks good (test on phone)
  - \[ \] Links in README point to live site

## 🎉 You’re Done\!

Once deployed, your package has: ✅ Professional documentation website ✅
Three comprehensive tutorials ✅ Complete function reference ✅
Searchable, organized, accessible ✅ Ready for users, collaborators, and
publication

**Congratulations on creating excellent documentation\!** 🎊
