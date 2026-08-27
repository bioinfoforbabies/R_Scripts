# ggplot2 Heatmap Basics

This example follows the card deck from data format → mapping → tiles → color → labels/theme.

## 1. Load packages

```r
library(ggplot2)
library(tidyr)
library(dplyr)
```

## 2. Start with a dummy wide dataset

Each row is a taxon, and each sample is stored in its own column.

```r
wide_df <- data.frame(
  taxon = c("Bacteria", "Fungi", "Archaea", "Protista", "Virus"),
  S1 = c(12, 4, 8, 3, 6),
  S2 = c(8, 15, 5, 7, 2),
  S3 = c(3, 9, 14, 10, 8),
  S4 = c(6, 11, 12, 4, 13),
  S5 = c(10, 7, 15, 9, 5)
)

wide_df
```

The table looks like this:

| taxon | S1 | S2 | S3 | S4 | S5 |
|---|---:|---:|---:|---:|---:|
| Bacteria | 12 | 8 | 3 | 6 | 10 |
| Fungi | 4 | 15 | 9 | 11 | 7 |
| Archaea | 8 | 5 | 14 | 12 | 15 |
| Protista | 3 | 7 | 10 | 4 | 9 |
| Virus | 6 | 2 | 8 | 13 | 5 |

## 3. Convert wide data to long data

For `geom_tile()`, it is convenient to have one sample–taxon combination per row.

```r
df <- wide_df |>
  pivot_longer(
    cols = -taxon,
    names_to = "sample",
    values_to = "abundance"
  )

df
```

The resulting structure is:

| sample | taxon | abundance |
|---|---|---:|
| S1 | Bacteria | 12 |
| S2 | Bacteria | 8 |
| S3 | Bacteria | 3 |
| S4 | Bacteria | 6 |
| S5 | Bacteria | 10 |
| ... | ... | ... |

## 4. Map the data with `aes()`

A heatmap needs three mappings:

- `x` → sample
- `y` → taxon
- `fill` → the numeric value represented by color

```r
ggplot(
  df,
  aes(
    x = sample,
    y = taxon,
    fill = abundance
  )
)
```

This only sets up the plot. No tiles are drawn yet.

## 5. Draw the heatmap cells with `geom_tile()`

```r
ggplot(
  df,
  aes(
    x = sample,
    y = taxon,
    fill = abundance
  )
) +
  geom_tile()
```

Each row in the long-format dataset becomes one tile in the heatmap.

## 6. Control the color scale

`fill` maps abundance values to color. A continuous gradient is appropriate here because `abundance` is numeric.

```r
ggplot(
  df,
  aes(
    x = sample,
    y = taxon,
    fill = abundance
  )
) +
  geom_tile() +
  scale_fill_gradient(
    low = "#F8F4E9",
    high = "#B9A5E3"
  )
```

Lower values are shown with lighter colors and higher values with darker colors.

## 7. Add labels and a theme

```r
ggplot(
  df,
  aes(
    x = sample,
    y = taxon,
    fill = abundance
  )
) +
  geom_tile(color = "white") +
  scale_fill_gradient(
    low = "#F8F4E9",
    high = "#B9A5E3"
  ) +
  labs(
    title = "Abundance heatmap",
    x = "Sample",
    y = "Taxon",
    fill = "Abundance"
  ) +
  theme_minimal()
```

## Complete script

```r
library(ggplot2)
library(tidyr)
library(dplyr)

wide_df <- data.frame(
  taxon = c("Bacteria", "Fungi", "Archaea", "Protista", "Virus"),
  S1 = c(12, 4, 8, 3, 6),
  S2 = c(8, 15, 5, 7, 2),
  S3 = c(3, 9, 14, 10, 8),
  S4 = c(6, 11, 12, 4, 13),
  S5 = c(10, 7, 15, 9, 5)
)

df <- wide_df |>
  pivot_longer(
    cols = -taxon,
    names_to = "sample",
    values_to = "abundance"
  )

ggplot(
  df,
  aes(
    x = sample,
    y = taxon,
    fill = abundance
  )
) +
  geom_tile(color = "white") +
  scale_fill_gradient(
    low = "#F8F4E9",
    high = "#B9A5E3"
  ) +
  labs(
    title = "Abundance heatmap",
    x = "Sample",
    y = "Taxon",
    fill = "Abundance"
  ) +
  theme_minimal()
```

## The basic pattern

```r
ggplot(data, aes(x, y, fill = value)) +
  geom_tile()
```

For a typical microbial abundance table:

```text
wide table
    ↓
pivot_longer()
    ↓
sample + taxon + abundance
    ↓
aes(x = sample, y = taxon, fill = abundance)
    ↓
geom_tile()
    ↓
color scale + labels + theme
```
