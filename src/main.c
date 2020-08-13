
#include "stm32l0xx_nucleo.h"

int main(void)
{
	BSP_LED_Init(LED2);

	for(;;)
	{
		BSP_LED_Toggle(LED2);

		for (int j = 0; j < 100000; j++)
			;
	}

	return 0;
}
