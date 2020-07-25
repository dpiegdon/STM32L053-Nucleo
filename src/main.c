
#include "stm32l0xx_nucleo.h"

int main(void)
{
	int i = 0;

	BSP_LED_Init(LED_GREEN);

	for(;;)
	{
		BSP_LED_Toggle(LED_GREEN);

		for (int j = 0; j < 100000; j++)
			;
	}

	return 0;
}
