**For Silver Bulletin specifically**

#### Which polls are included
- Polls that don't fake data
- Polls that are professionally done
- Polls that don't blend or smooth their data using methods such as MRP
- Polls that dont ask the voter who they support only after revealing leading information about the candidates
- Internal or campaign polls
- **Prioritize polls:** likely voters > registered voters > all adults

#### How polls are weighted
- More reliable polls have more influence on the averages
- Influence score is calculated on three factors:
  - The Silver Bulletin pollster rating, which is based on historical accuracy and whether it belongs to professional polling organizations that promote greater transparency and disclosure
  - The poll's sample size - although there are diminishing returns
  - Recency, determined empirically based on which settings best predict new polls over the subsequent two weeks

Also include precautions for polling agencies "flooding the zone" with disproportionate number of surveys.

NateSilver uses local polynomial regression, which smooths data, blends more aggressive and more conservative smoothing settings, and minimizes error.

#### House Effects
Persistent differences between a given firm's polls and those of other firms that survey the same race. The amount of the difference reduced is based on how often the poll comes out, so that it can be properly adjusted.

Firms with higher pollster ratings have more influence on what the model considers to be "true north", i.e. the unbiased average that other polls are adjusted toward.
