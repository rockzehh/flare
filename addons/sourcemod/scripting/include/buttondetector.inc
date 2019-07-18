/**
 * Button Detector
 * Developed by King Nothing - 2019
 */

#if defined _buttondetector_included
#endinput
#endif
#define _buttondetector_included

#define BDATTACK		1
#define BDJUMP 			2
#define BDDUCK 			4
#define BDFORWARD		8
#define BDBACK			16
#define BDUSE			32
#define BDCANCEL		64
#define BDLEFT 			128
#define BDRIGHT			256
#define BDMOVELEFT 		512
#define BDMOVERIGHT 	1024
#define BDATTACK2		2048
#define BDRUN			4096
#define BDRELOAD		8192
#define BDALT1			16384
#define BDALT2			32768
#define BDSCORE			65536
#define BDSPEED			131072
#define BDWALK			262144
#define BDZOOM			524288
#define BDWEAPON1		1048576
#define BDWEPAON2		2097152
#define BDBULLRUSH 		4194304
#define BDGRENADE1 		8388608
#define BDGRENADE2 		16777216
#define BDATTACK3		33554432

/**
 * Fires when a button is pressed.
 *
 * @param iClient	Client Index
 * @param iButton	Button Index
 *
 */
forward void BD_OnButtonPressed(int iClient, int iButton);

/**
 * Fires when a button is released.
 *
 * @param iClient	Client Index
 * @param iButton	Button Index
 *
 */
forward void BD_OnButtonReleased(int iClient, int iButton);
