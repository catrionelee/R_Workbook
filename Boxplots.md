# How to Make a Boxplot with Statistics

This is a guide to how to create some boxplots based on a dataframe.

**Contents**
1. [Preparing Your Data](https://github.com/catrionelee/R_Workbook/blob/main/Boxplots.md#preparing-your-data)
2. Boxplot with 1 comparision
3. Boxplot with 2 comparisions
4. Boxplot with 3 comparisions
5. Bxplot with 4 comparisions


## Preparing Your Data

First thing that needs to occur is preparing your data. For these statistics and the boxplotting to work, you need to format your dataframe into "long" format. Is thould look something like this:

| Var1 | Var2 | Var3 | Var4 | Y |
| :----: | :----: | :----: | :----: | :----: |
| A | 1 | 2 | A | 15 |
| B | 1 | 1| B | 20 |
| C | 2 | 1| A | 9 |

This is best conceptualized as `Var1` would be  your X, and Var2-4 will be associated metadata. Y needs to be a numberic value. X can be a character or numeric.
