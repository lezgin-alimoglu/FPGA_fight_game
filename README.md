# FPGA_fight_game

Term Project for **EE314 - Digital Circuits Laboratory** at **Middle East Technical University (METU)**.

This project is a hardware-based, minimalist **2-player fighting game** inspired by [FOOTSIES](https://hifight.github.io/footsies/), implemented using **Verilog HDL** and deployed on an **FPGA development board** (DE1-SoC).

> Special thanks to my amazing teammates **Fatih Çakır** and **Tuğrul Çağrı Alper**.

---

## 🎮 Game Overview

- **2D side-view fighting game**
- VGA output (640×480 @ 60Hz)
- Keypad-based input
- Designed for **real-time interaction**

Players can:
- Move left/right
- Perform attacks (neutral/directional)
- Block (by moving backwards)

Additional 1-player mode allows fighting against a **pseudo-random bot** opponent.

---

## 🔧 Features

### Game Mechanics
- Health: 3 points per player
- Block counter: 3 points
- Hitstun and Blockstun logic based on frame data
- Committal attacks with startup, active, and recovery phases
- Accurate **hitbox–hurtbox collision detection**
- Edge case handling: **Simultaneous hits**

### Game States
- Menu screen (1P vs 2P mode selection via switches)
- Countdown: "3, 2, 1, START"
- Game Over detection, winner display, reset to menu
- Timer and score display on **7-segment display**

### Inputs
- Each player: 3 buttons (Move Left, Move Right, Attack)
- Debouncing logic implemented
- Player 2 uses an **external keypad**

### Outputs
- VGA graphics for character sprites, HUD, and background
- 7-segment display and LEDs for health/block indicators
- Blinking LEDs on Game Over

---

## 🖥️ Technical Specifications

- **Language**: Verilog HDL
- **Platform**: DE1-SoC FPGA Board
- **Clock**: 60Hz game logic sync with VGA
- **Graphics**: 8-bit RGB (3-3-2 format)

---

