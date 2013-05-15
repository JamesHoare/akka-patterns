#include "rtest.h"
#include "count.h"

using namespace eigengo::akka;

class CounterTest : public OpenCVTest {
protected:
	CoinCounter counter;
};

TEST_F(CounterTest, FourCoins1) {
	auto image = load("coins.jpg");
	EXPECT_EQ(4, counter.count(image).size());
}

TEST_F(CounterTest, FourCoins2) {
	auto image = load("coins2.jpg");
	EXPECT_EQ(4, counter.count(image).size());
}