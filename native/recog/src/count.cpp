#include "count.h"
#include <opencv2/gpu/gpu.hpp>

using namespace eigengo::akka;

std::vector<Coin> CoinCounter::countCpu(const cv::Mat &image) {
	using namespace cv;
	
	std::vector<Coin> coins;
	
	Mat dst;
	std::vector<Vec3f> circles;
	
	cvtColor(image, dst, CV_BGR2GRAY);
	GaussianBlur(dst, dst, Size(3, 3), 2, 2);
	Canny(dst, dst, 1000, 1700, 5);
	GaussianBlur(dst, dst, Size(9, 9), 3, 3);
	HoughCircles(dst, circles, CV_HOUGH_GRADIENT,
				 1,    // dp
				 80,   // min dist
				 100,  // canny1
				 105,  // canny2
				 60,   // min radius
				 0     // max radius
				 );
	
	for (size_t i = 0; i < circles.size(); i++) {
		Coin coin;
		coin.center = circles[i][0];
		coin.radius = circles[i][1];
		coins.push_back(coin);
	}
	
	/*
	 Mat x(image);
	 for (size_t i = 0; i < circles.size(); i++ ) {
	 Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
	 int radius = cvRound(circles[i][2]);
	 // draw the circle center
	 circle(x, center, 3, Scalar(0,255,0), -1, 8, 0 );
	 // draw the circle outline
	 circle(x, center, radius, Scalar(0,0,255), 3, 8, 0 );
	 }
	 cv::imshow("", dst);
	 cv::waitKey();
	*/
	 
	return coins;
}

std::vector<Coin> CoinCounter::countGpu(const cv::Mat &image) {
	// K D D D D D D D D D      ... K
	
	// 10 fps ~> 50 kB/s
	
	throw "Not here yet";
}

std::vector<Coin> CoinCounter::count(const cv::Mat &image) {
	if (cv::gpu::getCudaEnabledDeviceCount() > 0) return countGpu(image);
	return countCpu(image);
}