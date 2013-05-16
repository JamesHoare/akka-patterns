#include "main.h"
#include "im.h"
#include "jzon.h"

using namespace eigengo::akka;

Main::Main(const std::string queue, const std::string exchange, const std::string routingKey) :
RabbitRpcServer::RabbitRpcServer(queue, exchange, routingKey) {
	
}

std::string Main::handleMessage(const AmqpClient::BasicMessage::ptr_t message, const AmqpClient::Channel::ptr_t channel) {
	ImageMessage imageMessage(message);
	
	auto imageData = imageMessage.headImage();
	auto imageMat = cv::imdecode(cv::Mat(imageData), 1);
	// ponies & unicorns
	auto coins = coinCounter.count(imageMat);
	
	Jzon::Array root;
	for (auto i = coins.begin(); i != coins.end(); ++i) {
		auto coin = *i;
		Jzon::Object coinJson;
		coinJson.Add("center", coin.center);
		coinJson.Add("radius", coin.radius);
		root.Add("accepted", recognised);
	}
	Jzon::Writer writer(root, Jzon::NoFormat);
	writer.Write();

	return writer.GetResult();
}

int main(int argc, char** argv) {
	Main main("recog", "amq.direct", "recog.key");
	main.runAndJoin(8);
	return 0;
}