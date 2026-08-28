FPC=fpc
BUILD_DIR=build
FLAGS=-Mobjfpc -Sh -Fu./src/domain -Fu./src/application -Fu./src/presentation

all:
	mkdir -p $(BUILD_DIR)
	$(FPC) $(FLAGS) -FE$(BUILD_DIR) -FU$(BUILD_DIR) -o$(BUILD_DIR)/TodoApp TodoApp.lpr

debug:
	mkdir -p $(BUILD_DIR)
	$(FPC) $(FLAGS) -FE$(BUILD_DIR) -FU$(BUILD_DIR) -g -gw3 -gl -O- -gs -gp godwarfcpp -o$(BUILD_DIR)/TodoApp TodoApp.lpr

clean:
	rm -rf $(BUILD_DIR)
