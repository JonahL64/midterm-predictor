#### Monte Carlo Simulation
- A method of estimating the value of an unknown quantity using the principles of inferential statistics
- **Inferential statistics**:
  - *Population*: a set of examples
  - *Sample*: a proper subset of a population (not the whole thing)
  - Key fact: a *random sample* tends to exhibit the same properties as the population from which it is drawn

#### Confidence
- Confidence in our sample depends on two things:
  - Sample size
  - Population
- As variance grows, we need larger samples to have the same degree of confidence
  - Variance = closeness of the probability results together

#### Law of Large Numbers (Bernulli's Law)
- In repeated independent tests with the same actual probability *p* of a particular outcome in each test, the chance that the fraction fo times that outcome occurs differs from *p* converges to zero as the number of trials goes to infinity

#### Regression to the Mean
- Following an extreme event (e.g., parents being usually tall), the next event is more likely to be less extreme
- If you spin a fair roulette wheel 10 times and get 100% reds, that is an extreme event (1/10^24)
- The gambler's fallacy says that you would get 10 blacks in a row to make up for the extra reds
- Regression to the mean is different: you will get fewer than 10 reds in the next spins
  - Just a less extreme event

#### Quantifying Variation in Data
- Compute the mean first
- For each little x in big X, compare the difference of that and the mean, and square the difference
  - *Why square*? It means you don't care whether the difference is positive or negative, but also it gives the outliers extra emphasis
- Then sum it
- Divide by the size of the set
- Standard deviation simply the square root of the variance
- Outliers can have a big effect - because we square the mean
- Standard deviation should always be considered relative to mean
  - Standard deviation by itself is a meaningless number

#### Confidence Intervals and Intervals
- Instead of estimating an unknown parameter by a single value (e.g., the mean of a set of trials), a confidence interval provides a range that is likely to contain the unknown value and a confidence that the unknown value lays within that range
- What does this mean?
  - If I were to conduct an infinite number of trials of this simulation, the actual probability would be within the confidence interval that % of time

##### Empirical Rule
- Under some assumptions discussed later:
  - ~68 of data within one standard deviation of mean
  - ~95% of data within 1.96 standard deviations of mean
  - ~99.7% of data within 3 standard deviations of mean
- Assumptions:
  - The mean estimation error is zero
  - The distribution of the errors is normal

#### Defining Distributions
- Use a probability distribution
- Captures notion of relative frequency with which a random variable takes on certain values
  - Discrete random variables drawn from finite set of values
  - Continuous random variables drawn from reals between two numbers (i.e., infinite set of numbers)
- For discrete variable, simply list list the probability of each value, must add up to 1
- Continuous case tricker, can't enumerate probability for each of an infinite set of values

#### Probability Density Function
- Distributions defined by probability density functions (PDFs)
- Probability of a random variable lying somewhere between two values
