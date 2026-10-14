class_name BoardGeometry
extends RefCounted

# Coordinates measured from the 640x480 board image.
# Rows run from the visually far/top rank to the near/bottom rank.
# Columns run from left to right in the image.
# Each tile: center, top_left, top_right, bottom_right, bottom_left.
static var TILES : Array = [
	[
		{"center": Vector2(84.22, 129.50), "corners": PackedVector2Array([Vector2(54.00, 108.00), Vector2(120.12, 108.00), Vector2(115.25, 151.00), Vector2(47.50, 151.00)])},
		{"center": Vector2(151.16, 129.50), "corners": PackedVector2Array([Vector2(120.12, 108.00), Vector2(186.25, 108.00), Vector2(183.00, 151.00), Vector2(115.25, 151.00)])},
		{"center": Vector2(218.09, 129.50), "corners": PackedVector2Array([Vector2(186.25, 108.00), Vector2(252.38, 108.00), Vector2(250.75, 151.00), Vector2(183.00, 151.00)])},
		{"center": Vector2(285.03, 129.50), "corners": PackedVector2Array([Vector2(252.38, 108.00), Vector2(318.50, 108.00), Vector2(318.50, 151.00), Vector2(250.75, 151.00)])},
		{"center": Vector2(351.97, 129.50), "corners": PackedVector2Array([Vector2(318.50, 108.00), Vector2(384.62, 108.00), Vector2(386.25, 151.00), Vector2(318.50, 151.00)])},
		{"center": Vector2(418.91, 129.50), "corners": PackedVector2Array([Vector2(384.62, 108.00), Vector2(450.75, 108.00), Vector2(454.00, 151.00), Vector2(386.25, 151.00)])},
		{"center": Vector2(485.84, 129.50), "corners": PackedVector2Array([Vector2(450.75, 108.00), Vector2(516.88, 108.00), Vector2(521.75, 151.00), Vector2(454.00, 151.00)])},
		{"center": Vector2(552.78, 129.50), "corners": PackedVector2Array([Vector2(516.88, 108.00), Vector2(583.00, 108.00), Vector2(589.50, 151.00), Vector2(521.75, 151.00)])}
	],
	[
		{"center": Vector2(78.53, 172.50), "corners": PackedVector2Array([Vector2(47.50, 151.00), Vector2(115.25, 151.00), Vector2(110.38, 194.00), Vector2(41.00, 194.00)])},
		{"center": Vector2(147.09, 172.50), "corners": PackedVector2Array([Vector2(115.25, 151.00), Vector2(183.00, 151.00), Vector2(179.75, 194.00), Vector2(110.38, 194.00)])},
		{"center": Vector2(215.66, 172.50), "corners": PackedVector2Array([Vector2(183.00, 151.00), Vector2(250.75, 151.00), Vector2(249.12, 194.00), Vector2(179.75, 194.00)])},
		{"center": Vector2(284.22, 172.50), "corners": PackedVector2Array([Vector2(250.75, 151.00), Vector2(318.50, 151.00), Vector2(318.50, 194.00), Vector2(249.12, 194.00)])},
		{"center": Vector2(352.78, 172.50), "corners": PackedVector2Array([Vector2(318.50, 151.00), Vector2(386.25, 151.00), Vector2(387.88, 194.00), Vector2(318.50, 194.00)])},
		{"center": Vector2(421.34, 172.50), "corners": PackedVector2Array([Vector2(386.25, 151.00), Vector2(454.00, 151.00), Vector2(457.25, 194.00), Vector2(387.88, 194.00)])},
		{"center": Vector2(489.91, 172.50), "corners": PackedVector2Array([Vector2(454.00, 151.00), Vector2(521.75, 151.00), Vector2(526.62, 194.00), Vector2(457.25, 194.00)])},
		{"center": Vector2(558.47, 172.50), "corners": PackedVector2Array([Vector2(521.75, 151.00), Vector2(589.50, 151.00), Vector2(596.00, 194.00), Vector2(526.62, 194.00)])}
	],
	[
		{"center": Vector2(72.72, 216.00), "corners": PackedVector2Array([Vector2(41.00, 194.00), Vector2(110.38, 194.00), Vector2(105.33, 238.00), Vector2(34.20, 238.00)])},
		{"center": Vector2(142.97, 216.00), "corners": PackedVector2Array([Vector2(110.38, 194.00), Vector2(179.75, 194.00), Vector2(176.45, 238.00), Vector2(105.33, 238.00)])},
		{"center": Vector2(213.22, 216.00), "corners": PackedVector2Array([Vector2(179.75, 194.00), Vector2(249.12, 194.00), Vector2(247.57, 238.00), Vector2(176.45, 238.00)])},
		{"center": Vector2(283.48, 216.00), "corners": PackedVector2Array([Vector2(249.12, 194.00), Vector2(318.50, 194.00), Vector2(318.70, 238.00), Vector2(247.57, 238.00)])},
		{"center": Vector2(353.73, 216.00), "corners": PackedVector2Array([Vector2(318.50, 194.00), Vector2(387.88, 194.00), Vector2(389.82, 238.00), Vector2(318.70, 238.00)])},
		{"center": Vector2(423.98, 216.00), "corners": PackedVector2Array([Vector2(387.88, 194.00), Vector2(457.25, 194.00), Vector2(460.95, 238.00), Vector2(389.82, 238.00)])},
		{"center": Vector2(494.23, 216.00), "corners": PackedVector2Array([Vector2(457.25, 194.00), Vector2(526.62, 194.00), Vector2(532.08, 238.00), Vector2(460.95, 238.00)])},
		{"center": Vector2(564.48, 216.00), "corners": PackedVector2Array([Vector2(526.62, 194.00), Vector2(596.00, 194.00), Vector2(603.20, 238.00), Vector2(532.08, 238.00)])}
	],
	[
		{"center": Vector2(66.76, 260.50), "corners": PackedVector2Array([Vector2(34.20, 238.00), Vector2(105.33, 238.00), Vector2(100.23, 283.00), Vector2(27.30, 283.00)])},
		{"center": Vector2(138.79, 260.50), "corners": PackedVector2Array([Vector2(105.33, 238.00), Vector2(176.45, 238.00), Vector2(173.15, 283.00), Vector2(100.23, 283.00)])},
		{"center": Vector2(210.81, 260.50), "corners": PackedVector2Array([Vector2(176.45, 238.00), Vector2(247.57, 238.00), Vector2(246.08, 283.00), Vector2(173.15, 283.00)])},
		{"center": Vector2(282.84, 260.50), "corners": PackedVector2Array([Vector2(247.57, 238.00), Vector2(318.70, 238.00), Vector2(319.00, 283.00), Vector2(246.08, 283.00)])},
		{"center": Vector2(354.86, 260.50), "corners": PackedVector2Array([Vector2(318.70, 238.00), Vector2(389.82, 238.00), Vector2(391.93, 283.00), Vector2(319.00, 283.00)])},
		{"center": Vector2(426.89, 260.50), "corners": PackedVector2Array([Vector2(389.82, 238.00), Vector2(460.95, 238.00), Vector2(464.85, 283.00), Vector2(391.93, 283.00)])},
		{"center": Vector2(498.91, 260.50), "corners": PackedVector2Array([Vector2(460.95, 238.00), Vector2(532.08, 238.00), Vector2(537.78, 283.00), Vector2(464.85, 283.00)])},
		{"center": Vector2(570.94, 260.50), "corners": PackedVector2Array([Vector2(532.08, 238.00), Vector2(603.20, 238.00), Vector2(610.70, 283.00), Vector2(537.78, 283.00)])}
	],
	[
		{"center": Vector2(60.67, 306.00), "corners": PackedVector2Array([Vector2(27.30, 283.00), Vector2(100.23, 283.00), Vector2(94.97, 329.00), Vector2(20.20, 329.00)])},
		{"center": Vector2(134.53, 306.00), "corners": PackedVector2Array([Vector2(100.23, 283.00), Vector2(173.15, 283.00), Vector2(169.75, 329.00), Vector2(94.97, 329.00)])},
		{"center": Vector2(208.38, 306.00), "corners": PackedVector2Array([Vector2(173.15, 283.00), Vector2(246.08, 283.00), Vector2(244.52, 329.00), Vector2(169.75, 329.00)])},
		{"center": Vector2(282.23, 306.00), "corners": PackedVector2Array([Vector2(246.08, 283.00), Vector2(319.00, 283.00), Vector2(319.30, 329.00), Vector2(244.52, 329.00)])},
		{"center": Vector2(356.07, 306.00), "corners": PackedVector2Array([Vector2(319.00, 283.00), Vector2(391.93, 283.00), Vector2(394.07, 329.00), Vector2(319.30, 329.00)])},
		{"center": Vector2(429.93, 306.00), "corners": PackedVector2Array([Vector2(391.93, 283.00), Vector2(464.85, 283.00), Vector2(468.85, 329.00), Vector2(394.07, 329.00)])},
		{"center": Vector2(503.78, 306.00), "corners": PackedVector2Array([Vector2(464.85, 283.00), Vector2(537.78, 283.00), Vector2(543.62, 329.00), Vector2(468.85, 329.00)])},
		{"center": Vector2(577.62, 306.00), "corners": PackedVector2Array([Vector2(537.78, 283.00), Vector2(610.70, 283.00), Vector2(618.40, 329.00), Vector2(543.62, 329.00)])}
	],
	[
		{"center": Vector2(54.37, 353.00), "corners": PackedVector2Array([Vector2(20.20, 329.00), Vector2(94.97, 329.00), Vector2(89.50, 377.00), Vector2(12.80, 377.00)])},
		{"center": Vector2(130.11, 353.00), "corners": PackedVector2Array([Vector2(94.97, 329.00), Vector2(169.75, 329.00), Vector2(166.20, 377.00), Vector2(89.50, 377.00)])},
		{"center": Vector2(205.84, 353.00), "corners": PackedVector2Array([Vector2(169.75, 329.00), Vector2(244.52, 329.00), Vector2(242.90, 377.00), Vector2(166.20, 377.00)])},
		{"center": Vector2(281.58, 353.00), "corners": PackedVector2Array([Vector2(244.52, 329.00), Vector2(319.30, 329.00), Vector2(319.60, 377.00), Vector2(242.90, 377.00)])},
		{"center": Vector2(357.32, 353.00), "corners": PackedVector2Array([Vector2(319.30, 329.00), Vector2(394.07, 329.00), Vector2(396.30, 377.00), Vector2(319.60, 377.00)])},
		{"center": Vector2(433.06, 353.00), "corners": PackedVector2Array([Vector2(394.07, 329.00), Vector2(468.85, 329.00), Vector2(473.00, 377.00), Vector2(396.30, 377.00)])},
		{"center": Vector2(508.79, 353.00), "corners": PackedVector2Array([Vector2(468.85, 329.00), Vector2(543.62, 329.00), Vector2(549.70, 377.00), Vector2(473.00, 377.00)])},
		{"center": Vector2(584.53, 353.00), "corners": PackedVector2Array([Vector2(543.62, 329.00), Vector2(618.40, 329.00), Vector2(626.40, 377.00), Vector2(549.70, 377.00)])}
	],
	[
		{"center": Vector2(47.71, 402.50), "corners": PackedVector2Array([Vector2(12.80, 377.00), Vector2(89.50, 377.00), Vector2(83.64, 428.00), Vector2(4.90, 428.00)])},
		{"center": Vector2(125.43, 402.50), "corners": PackedVector2Array([Vector2(89.50, 377.00), Vector2(166.20, 377.00), Vector2(162.38, 428.00), Vector2(83.64, 428.00)])},
		{"center": Vector2(203.15, 402.50), "corners": PackedVector2Array([Vector2(166.20, 377.00), Vector2(242.90, 377.00), Vector2(241.11, 428.00), Vector2(162.38, 428.00)])},
		{"center": Vector2(280.87, 402.50), "corners": PackedVector2Array([Vector2(242.90, 377.00), Vector2(319.60, 377.00), Vector2(319.85, 428.00), Vector2(241.11, 428.00)])},
		{"center": Vector2(358.58, 402.50), "corners": PackedVector2Array([Vector2(319.60, 377.00), Vector2(396.30, 377.00), Vector2(398.59, 428.00), Vector2(319.85, 428.00)])},
		{"center": Vector2(436.30, 402.50), "corners": PackedVector2Array([Vector2(396.30, 377.00), Vector2(473.00, 377.00), Vector2(477.32, 428.00), Vector2(398.59, 428.00)])},
		{"center": Vector2(514.02, 402.50), "corners": PackedVector2Array([Vector2(473.00, 377.00), Vector2(549.70, 377.00), Vector2(556.06, 428.00), Vector2(477.32, 428.00)])},
		{"center": Vector2(591.74, 402.50), "corners": PackedVector2Array([Vector2(549.70, 377.00), Vector2(626.40, 377.00), Vector2(634.80, 428.00), Vector2(556.06, 428.00)])}
	],
	[
		{"center": Vector2(40.74, 454.00), "corners": PackedVector2Array([Vector2(4.90, 428.00), Vector2(83.64, 428.00), Vector2(77.61, 480.00), Vector2(-3.20, 480.00)])},
		{"center": Vector2(120.51, 454.00), "corners": PackedVector2Array([Vector2(83.64, 428.00), Vector2(162.38, 428.00), Vector2(158.43, 480.00), Vector2(77.61, 480.00)])},
		{"center": Vector2(200.29, 454.00), "corners": PackedVector2Array([Vector2(162.38, 428.00), Vector2(241.11, 428.00), Vector2(239.24, 480.00), Vector2(158.43, 480.00)])},
		{"center": Vector2(280.06, 454.00), "corners": PackedVector2Array([Vector2(241.11, 428.00), Vector2(319.85, 428.00), Vector2(320.05, 480.00), Vector2(239.24, 480.00)])},
		{"center": Vector2(359.84, 454.00), "corners": PackedVector2Array([Vector2(319.85, 428.00), Vector2(398.59, 428.00), Vector2(400.86, 480.00), Vector2(320.05, 480.00)])},
		{"center": Vector2(439.61, 454.00), "corners": PackedVector2Array([Vector2(398.59, 428.00), Vector2(477.32, 428.00), Vector2(481.68, 480.00), Vector2(400.86, 480.00)])},
		{"center": Vector2(519.39, 454.00), "corners": PackedVector2Array([Vector2(477.32, 428.00), Vector2(556.06, 428.00), Vector2(562.49, 480.00), Vector2(481.68, 480.00)])},
		{"center": Vector2(599.16, 454.00), "corners": PackedVector2Array([Vector2(556.06, 428.00), Vector2(634.80, 428.00), Vector2(643.30, 480.00), Vector2(562.49, 480.00)])}
	]
]

static func tile(column: int, row: int) -> Dictionary:
	return TILES[row][column]

static func center(column: int, row: int) -> Vector2:
	return TILES[row][column]["center"]

static func corners(column: int, row: int) -> PackedVector2Array:
	return TILES[row][column]["corners"]
