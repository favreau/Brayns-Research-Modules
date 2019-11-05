/* Copyright (c) 2018, Cyrille Favreau
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
 *
 * This file is part of the reseach Brayns module
 * <https://github.com/favreau/Brayns-Research-Modules>
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License version 3.0 as published
 * by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include <common/ispc/renderer/AbstractRenderer.ih>

uniform const float positions[486][3] = {
    {0.13, 0.64, 0.35},    {0.14, 0.63, 0.31},    {0.17, 0.59, 0.30},
    {0.15, 0.55, 0.33},    {0.17, 0.57, 0.26},    {0.21, 0.54, 0.26},
    {0.13, 0.54, 0.25},    {0.14, 0.52, 0.30},    {0.10, 0.49, 0.31},
    {0.11, 0.45, 0.33},    {0.15, 0.43, 0.34},    {0.07, 0.43, 0.35},
    {0.03, 0.44, 0.34},    {-0.01, 0.42, 0.35},   {0.02, 0.48, 0.32},
    {0.06, 0.51, 0.30},    {0.25, 0.54, 0.22},    {0.28, 0.57, 0.23},
    {0.23, 0.55, 0.17},    {0.26, 0.49, 0.22},    {0.28, 0.47, 0.25},
    {0.28, 0.42, 0.24},    {0.24, 0.41, 0.26},    {0.29, 0.41, 0.19},
    {0.32, 0.38, 0.19},    {0.24, 0.40, 0.18},    {0.22, 0.38, 0.22},
    {0.17, 0.38, 0.23},    {0.15, 0.42, 0.21},    {0.11, 0.42, 0.22},
    {0.10, 0.37, 0.24},    {0.06, 0.35, 0.25},    {0.02, 0.36, 0.25},
    {0.07, 0.31, 0.27},    {0.11, 0.29, 0.27},    {0.12, 0.25, 0.29},
    {0.15, 0.31, 0.26},    {0.14, 0.35, 0.24},    {0.34, 0.35, 0.14},
    {0.38, 0.34, 0.14},    {0.32, 0.38, 0.10},    {0.31, 0.31, 0.14},
    {0.32, 0.28, 0.18},    {0.28, 0.24, 0.17},    {0.24, 0.26, 0.18},
    {0.28, 0.22, 0.13},    {0.30, 0.18, 0.13},    {0.23, 0.21, 0.12},
    {0.21, 0.23, 0.16},    {0.17, 0.26, 0.15},    {0.13, 0.25, 0.16},
    {0.12, 0.22, 0.18},    {0.10, 0.28, 0.15},    {0.11, 0.32, 0.13},
    {0.07, 0.35, 0.12},    {0.15, 0.33, 0.12},    {0.18, 0.30, 0.13},
    {0.31, 0.15, 0.09},    {0.35, 0.12, 0.09},    {0.31, 0.18, 0.05},
    {0.26, 0.12, 0.09},    {0.26, 0.09, 0.13},    {0.21, 0.07, 0.12},
    {0.18, 0.10, 0.12},    {0.21, 0.04, 0.07},    {0.18, 0.01, 0.07},
    {0.19, 0.08, 0.04},    {0.16, 0.10, 0.07},    {0.14, 0.14, 0.06},
    {0.17, 0.18, 0.04},    {0.14, 0.21, 0.04},    {0.10, 0.20, 0.05},
    {0.07, 0.23, 0.06},    {0.06, 0.27, 0.05},    {0.03, 0.21, 0.08},
    {0.03, 0.16, 0.09},    {-0.01, 0.15, 0.11},   {0.07, 0.14, 0.09},
    {0.10, 0.16, 0.07},    {0.18, -0.03, 0.04},   {0.20, -0.07, 0.06},
    {0.19, -0.02, -0.00},  {0.13, -0.05, 0.04},   {0.10, -0.05, 0.08},
    {0.06, -0.03, 0.07},   {0.06, 0.01, 0.05},    {0.03, -0.05, 0.03},
    {-0.01, -0.07, 0.04},  {0.03, -0.02, -0.01},  {0.03, 0.02, 0.02},
    {0.05, 0.06, -0.00},   {0.09, 0.07, -0.02},   {0.10, 0.11, -0.04},
    {0.06, 0.13, -0.03},   {0.04, 0.18, -0.04},   {0.07, 0.21, -0.06},
    {-0.00, 0.19, -0.03},  {-0.03, 0.16, -0.01},  {-0.02, 0.11, -0.00},
    {0.03, 0.10, -0.01},   {-0.04, -0.10, 0.00},  {-0.07, -0.13, 0.03},
    {-0.01, -0.12, -0.03}, {-0.07, -0.06, -0.02}, {-0.11, -0.05, 0.01},
    {-0.13, -0.01, -0.02}, {-0.09, 0.02, -0.03},  {-0.15, -0.03, -0.06},
    {-0.20, -0.02, -0.06}, {-0.13, -0.01, -0.10}, {-0.11, 0.03, -0.08},
    {-0.07, 0.05, -0.10},  {-0.03, 0.03, -0.10},  {0.00, 0.06, -0.12},
    {-0.02, 0.10, -0.13},  {-0.00, 0.14, -0.14},  {0.04, 0.15, -0.15},
    {-0.03, 0.17, -0.14},  {-0.07, 0.17, -0.12},  {-0.09, 0.13, -0.11},
    {-0.06, 0.09, -0.11},  {-0.23, -0.03, -0.10}, {-0.28, -0.03, -0.09},
    {-0.21, -0.07, -0.13}, {-0.23, 0.01, -0.13},  {-0.24, 0.05, -0.11},
    {-0.23, 0.09, -0.15},  {-0.18, 0.09, -0.16},  {-0.25, 0.08, -0.19},
    {-0.29, 0.10, -0.19},  {-0.22, 0.08, -0.23},  {-0.18, 0.11, -0.20},
    {-0.13, 0.10, -0.21},  {-0.11, 0.13, -0.23},  {-0.12, 0.17, -0.23},
    {-0.06, 0.12, -0.24},  {-0.05, 0.08, -0.24},  {-0.01, 0.07, -0.25},
    {-0.07, 0.04, -0.23},  {-0.06, -0.00, -0.23}, {-0.12, 0.05, -0.21},
    {-0.32, 0.10, -0.24},  {-0.37, 0.11, -0.23},  {-0.32, 0.06, -0.26},
    {-0.30, 0.14, -0.27},  {-0.30, 0.18, -0.25},  {-0.27, 0.21, -0.29},
    {-0.23, 0.18, -0.29},  {-0.29, 0.21, -0.33},  {-0.30, 0.26, -0.34},
    {-0.25, 0.19, -0.36},  {-0.21, 0.20, -0.33},  {-0.17, 0.16, -0.34},
    {-0.13, 0.18, -0.35},  {-0.12, 0.22, -0.35},  {-0.10, 0.15, -0.35},
    {-0.10, 0.10, -0.35},  {-0.07, 0.08, -0.35},  {-0.15, 0.09, -0.34},
    {-0.16, 0.04, -0.34},  {-0.18, 0.12, -0.34},  {-0.32, 0.27, -0.39},
    {-0.35, 0.31, -0.39},  {-0.33, 0.23, -0.42},  {-0.27, 0.28, -0.41},
    {-0.25, 0.32, -0.39},  {-0.20, 0.33, -0.42},  {-0.18, 0.29, -0.42},
    {-0.21, 0.34, -0.47},  {-0.18, 0.38, -0.48},  {-0.20, 0.30, -0.49},
    {-0.16, 0.28, -0.46},  {-0.15, 0.23, -0.47},  {-0.11, 0.22, -0.47},
    {-0.08, 0.25, -0.48},  {-0.10, 0.18, -0.47},  {-0.13, 0.15, -0.47},
    {-0.12, 0.10, -0.46},  {-0.17, 0.16, -0.46},  {-0.18, 0.20, -0.46},
    {-0.20, 0.41, -0.52},  {-0.18, 0.46, -0.51},  {-0.25, 0.40, -0.53},
    {-0.17, 0.39, -0.56},  {-0.12, 0.40, -0.56},  {-0.10, 0.37, -0.59},
    {-0.11, 0.32, -0.58},  {-0.12, 0.37, -0.64},  {-0.09, 0.37, -0.67},
    {-0.15, 0.33, -0.64},  {-0.12, 0.30, -0.62},  {-0.14, 0.26, -0.61},
    {-0.18, 0.24, -0.60},  {-0.18, 0.20, -0.59},  {-0.14, 0.19, -0.59},
    {-0.12, 0.14, -0.58},  {-0.14, 0.11, -0.57},  {-0.08, 0.14, -0.59},
    {-0.05, 0.18, -0.60},  {-0.01, 0.17, -0.61},  {-0.07, 0.22, -0.61},
    {-0.11, 0.22, -0.60},  {-0.07, 0.41, -0.70},  {-0.07, 0.45, -0.67},
    {-0.10, 0.42, -0.74},  {-0.02, 0.40, -0.71},  {0.01, 0.40, -0.68},
    {0.04, 0.36, -0.68},   {0.01, 0.33, -0.68},   {0.06, 0.36, -0.73},
    {0.11, 0.35, -0.72},   {0.04, 0.33, -0.75},   {0.03, 0.29, -0.71},
    {-0.01, 0.27, -0.72},  {-0.01, 0.22, -0.72},  {0.03, 0.21, -0.71},
    {-0.04, 0.19, -0.72},  {-0.08, 0.21, -0.73},  {-0.12, 0.19, -0.73},
    {-0.09, 0.26, -0.73},  {-0.05, 0.29, -0.73},  {0.14, 0.36, -0.76},
    {0.19, 0.37, -0.75},   {0.13, 0.40, -0.79},   {0.14, 0.31, -0.79},
    {0.17, 0.28, -0.78},   {0.16, 0.24, -0.81},   {0.11, 0.23, -0.80},
    {0.16, 0.25, -0.86},   {0.20, 0.22, -0.88},   {0.12, 0.24, -0.88},
    {0.10, 0.21, -0.84},   {0.05, 0.21, -0.84},   {0.02, 0.24, -0.85},
    {-0.02, 0.23, -0.85},  {-0.02, 0.19, -0.84},  {-0.06, 0.16, -0.83},
    {-0.10, 0.17, -0.83},  {-0.04, 0.12, -0.82},  {0.00, 0.10, -0.82},
    {0.01, 0.06, -0.81},   {0.04, 0.13, -0.83},   {0.02, 0.17, -0.83},
    {-0.25, -0.10, -0.80}, {-0.22, -0.13, -0.83}, {-0.18, -0.13, -0.82},
    {-0.16, -0.08, -0.83}, {-0.16, -0.13, -0.77}, {-0.12, -0.16, -0.76},
    {-0.16, -0.09, -0.75}, {-0.14, -0.07, -0.79}, {-0.15, -0.02, -0.80},
    {-0.11, 0.01, -0.80},  {-0.08, 0.00, -0.80},  {-0.13, 0.06, -0.81},
    {-0.17, 0.07, -0.81},  {-0.18, 0.11, -0.82},  {-0.20, 0.04, -0.81},
    {-0.19, -0.01, -0.80}, {-0.11, -0.18, -0.72}, {-0.11, -0.23, -0.72},
    {-0.15, -0.17, -0.68}, {-0.06, -0.16, -0.71}, {-0.03, -0.17, -0.74},
    {0.00, -0.13, -0.72},  {-0.01, -0.09, -0.73}, {0.01, -0.14, -0.67},
    {0.06, -0.15, -0.67},  {-0.00, -0.10, -0.65}, {0.00, -0.06, -0.69},
    {-0.03, -0.03, -0.68}, {-0.08, -0.03, -0.68}, {-0.10, 0.00, -0.68},
    {-0.07, 0.03, -0.69},  {-0.07, 0.08, -0.69},  {-0.11, 0.10, -0.69},
    {-0.03, 0.10, -0.70},  {0.01, 0.08, -0.70},   {0.04, 0.11, -0.71},
    {0.01, 0.04, -0.70},   {-0.03, 0.02, -0.69},  {0.08, -0.15, -0.62},
    {0.12, -0.18, -0.62},  {0.05, -0.17, -0.59},  {0.10, -0.10, -0.61},
    {0.13, -0.08, -0.63},  {0.13, -0.03, -0.62},  {0.09, -0.02, -0.62},
    {0.14, -0.03, -0.57},  {0.19, -0.03, -0.56},  {0.12, 0.01, -0.56},
    {0.08, 0.02, -0.60},   {0.04, 0.02, -0.58},   {0.02, 0.06, -0.59},
    {0.04, 0.09, -0.60},   {-0.03, 0.07, -0.58},  {-0.05, 0.03, -0.56},
    {-0.09, 0.03, -0.55},  {-0.03, -0.01, -0.56}, {0.02, -0.01, -0.57},
    {0.21, -0.02, -0.51},  {0.26, -0.03, -0.52},  {0.18, -0.03, -0.48},
    {0.21, 0.04, -0.51},   {0.24, 0.06, -0.54},   {0.22, 0.11, -0.53},
    {0.18, 0.11, -0.53},   {0.24, 0.13, -0.49},   {0.25, 0.18, -0.50},
    {0.19, 0.13, -0.46},   {0.16, 0.13, -0.50},   {0.12, 0.11, -0.48},
    {0.11, 0.07, -0.47},   {0.07, 0.06, -0.46},   {0.05, 0.09, -0.47},
    {-0.00, 0.10, -0.47},  {-0.03, 0.08, -0.46},  {-0.01, 0.14, -0.49},
    {0.02, 0.18, -0.50},   {0.00, 0.22, -0.51},   {0.06, 0.17, -0.50},
    {0.07, 0.13, -0.49},   {0.26, 0.21, -0.46},   {0.30, 0.24, -0.47},
    {0.27, 0.18, -0.42},   {0.22, 0.24, -0.45},   {0.21, 0.26, -0.49},
    {0.17, 0.29, -0.48},   {0.13, 0.27, -0.47},   {0.18, 0.32, -0.45},
    {0.16, 0.37, -0.45},   {0.16, 0.30, -0.41},   {0.12, 0.28, -0.43},
    {0.10, 0.24, -0.41},   {0.13, 0.20, -0.40},   {0.10, 0.17, -0.38},
    {0.06, 0.18, -0.38},   {0.02, 0.16, -0.37},   {0.01, 0.12, -0.36},
    {-0.02, 0.19, -0.38},  {-0.01, 0.23, -0.40},  {0.02, 0.25, -0.41},
    {0.06, 0.22, -0.40},   {0.16, 0.40, -0.42},   {0.16, 0.45, -0.44},
    {0.20, 0.40, -0.39},   {0.11, 0.40, -0.39},   {0.07, 0.40, -0.42},
    {0.03, 0.40, -0.39},   {0.03, 0.35, -0.37},   {0.04, 0.43, -0.35},
    {-0.00, 0.45, -0.34},  {0.05, 0.39, -0.31},   {0.02, 0.36, -0.33},
    {0.04, 0.31, -0.31},   {0.08, 0.30, -0.31},   {0.08, 0.26, -0.29},
    {0.04, 0.24, -0.28},   {0.02, 0.20, -0.27},   {0.05, 0.17, -0.26},
    {-0.02, 0.20, -0.27},  {-0.05, 0.23, -0.28},  {-0.03, 0.27, -0.29},
    {0.01, 0.28, -0.29},   {-0.01, 0.48, -0.30},  {-0.04, 0.52, -0.31},
    {0.03, 0.49, -0.28},   {-0.05, 0.45, -0.27},  {-0.09, 0.44, -0.29},
    {-0.11, 0.41, -0.26},  {-0.07, 0.37, -0.25},  {-0.12, 0.43, -0.21},
    {-0.16, 0.43, -0.20},  {-0.09, 0.40, -0.18},  {-0.09, 0.35, -0.21},
    {-0.05, 0.33, -0.19},  {-0.05, 0.29, -0.18},  {-0.09, 0.27, -0.17},
    {-0.01, 0.26, -0.17},  {0.03, 0.28, -0.17},   {0.06, 0.25, -0.17},
    {0.03, 0.32, -0.19},   {0.08, 0.34, -0.19},   {-0.01, 0.35, -0.20},
    {-0.18, 0.45, -0.16},  {-0.23, 0.47, -0.17},  {-0.15, 0.48, -0.14},
    {-0.19, 0.41, -0.13},  {-0.21, 0.37, -0.14},  {-0.21, 0.34, -0.11},
    {-0.17, 0.32, -0.11},  {-0.22, 0.35, -0.06},  {-0.26, 0.32, -0.05},
    {-0.18, 0.34, -0.04},  {-0.16, 0.30, -0.06},  {-0.11, 0.30, -0.06},
    {-0.09, 0.26, -0.05},  {-0.11, 0.23, -0.04},  {-0.05, 0.26, -0.05},
    {-0.02, 0.30, -0.06},  {0.02, 0.29, -0.06},   {-0.04, 0.34, -0.07},
    {-0.01, 0.38, -0.08},  {-0.09, 0.34, -0.07},  {-0.28, 0.33, 0.00},
    {-0.33, 0.31, -0.00},  {-0.27, 0.37, 0.02},   {-0.25, 0.29, 0.03},
    {-0.26, 0.25, 0.01},   {-0.23, 0.22, 0.05},   {-0.18, 0.23, 0.04},
    {-0.24, 0.23, 0.10},   {-0.27, 0.20, 0.12},   {-0.20, 0.25, 0.12},
    {-0.16, 0.22, 0.08},   {-0.12, 0.25, 0.08},   {-0.08, 0.23, 0.08},
    {-0.08, 0.19, 0.09},   {-0.05, 0.25, 0.07},   {-0.05, 0.30, 0.06},
    {-0.01, 0.32, 0.05},   {-0.09, 0.32, 0.06},   {-0.13, 0.30, 0.07},
    {-0.28, 0.21, 0.17},   {-0.32, 0.18, 0.18},   {-0.29, 0.26, 0.18},
    {-0.24, 0.20, 0.20},   {-0.23, 0.15, 0.20},   {-0.19, 0.15, 0.23},
    {-0.15, 0.18, 0.21},   {-0.19, 0.18, 0.28},   {-0.16, 0.16, 0.31},
    {-0.17, 0.22, 0.27},   {-0.13, 0.21, 0.24},   {-0.11, 0.25, 0.22},
    {-0.13, 0.28, 0.21},   {-0.10, 0.31, 0.19},   {-0.06, 0.29, 0.19},
    {-0.02, 0.30, 0.17},   {-0.01, 0.34, 0.15},   {0.01, 0.27, 0.18},
    {0.00, 0.23, 0.20},    {0.04, 0.20, 0.20},    {-0.04, 0.22, 0.21},
    {-0.07, 0.25, 0.21},   {-0.18, 0.12, 0.34},   {-0.21, 0.08, 0.32},
    {-0.21, 0.15, 0.38},   {-0.14, 0.10, 0.37},   {-0.11, 0.07, 0.34},
    {-0.06, 0.09, 0.35},   {-0.06, 0.13, 0.33},   {-0.05, 0.10, 0.40},
    {-0.02, 0.06, 0.42},   {-0.04, 0.14, 0.40},   {-0.02, 0.15, 0.35},
    {-0.03, 0.20, 0.34},   {0.01, 0.22, 0.32},    {0.04, 0.20, 0.32},
    {0.00, 0.26, 0.31},    {-0.04, 0.28, 0.31},   {-0.04, 0.33, 0.30},
    {-0.07, 0.26, 0.33},   {-0.07, 0.22, 0.35},   {-0.01, 0.07, 0.47},
    {-0.00, 0.02, 0.49},   {-0.05, 0.10, 0.50},   {0.03, 0.10, 0.48},
    {0.07, 0.08, 0.46},    {0.11, 0.12, 0.46},    {0.09, 0.15, 0.43},
    {0.11, 0.14, 0.50},    {0.13, 0.12, 0.54},    {0.13, 0.18, 0.49},
    {0.11, 0.19, 0.44},    {0.07, 0.22, 0.44},    {0.03, 0.22, 0.45},
    {0.00, 0.25, 0.44},    {0.03, 0.28, 0.42},    {0.03, 0.32, 0.40},
    {-0.01, 0.35, 0.40},   {0.06, 0.34, 0.39},    {0.11, 0.32, 0.39},
    {0.14, 0.35, 0.37},    {0.11, 0.28, 0.40},    {0.07, 0.26, 0.42}};

struct VoxelizerRenderer
{
    Renderer super;

    // Rendering attributes
    const uniform Light* uniform* uniform lights;
    uint32 numLights;
    const uniform ExtendedOBJMaterial* uniform* uniform materials;
    uint32 numMaterials;
    vec3f bgColor;
    float shadows;
    bool shadingEnabled;
    float softShadows;
    float ambientOcclusionStrength;
    float ambientOcclusionDistance;
    bool electronShadingEnabled;
    int randomNumber;
    float timestamp;
    int spp;

    // Transfer function / Color map attributes
    uniform vec4f* uniform colorMap;
    uniform vec3f* uniform emissionIntensitiesMap;
    uint32 colorMapSize;
    float colorMapMinValue;
    float colorMapRange;
    float threshold;

    float pixelOpacity;

    // Volume dimension
    vec3f volumeDimensions;
    uint32 volumeSamplesPerRay;

    // Divider
    float divider;
};

inline varying bool intersectBox(const varying Ray& ray, const vec3f& aabbMin,
                                 const vec3f& aabbMax, varying float& t0,
                                 varying float& t1)
{
    Ray r = ray;
    vec3f invR = 1.f / r.dir;
    vec3f tbot = invR * (aabbMin - r.org);
    vec3f ttop = invR * (aabbMax - r.org);
    vec3f tmin = min(ttop, tbot);
    vec3f tmax = max(ttop, tbot);
    vec2f t = make_vec2f(max(tmin.x, tmin.y), max(tmin.x, tmin.z));
    t0 = max(t.x, t.y);
    t = make_vec2f(min(tmax.x, tmax.y), min(tmax.x, tmax.z));
    t1 = min(t.x, t.y);
    return (t0 <= t1);
}

inline varying vec4f getVoxelColor(
    const uniform VoxelizerRenderer* uniform self, const vec3f& point)
{
    float value = 0.f;
    for (int i = 0; i < 486; ++i)
    {
        const vec3f p =
            make_vec3f(positions[i][0], positions[i][1], positions[i][2]);
        const float len = length(p - point);
        const float field = 1.f / (len * len);
        value += field;
    }

    value = clamp(value / self->divider, 0.f, 1.f);
    return make_vec4f(0.f, 1.f - value, value,
                      (value < 0.2f ? 0.f : self->pixelOpacity));

    //    const uint8 voxelValue = value;
    //    const float normalizedValue =
    //        (voxelValue - self->colorMapMinValue) / self->colorMapRange;

    //    // Voxel color according to colormap value
    //    return self->colorMap[self->colorMapSize * normalizedValue];
}

inline float getShadowContribution(
    const uniform VoxelizerRenderer* uniform self, varying ScreenSample& sample,
    const vec3f point)
{
    uniform int i = 0;
    float pathOpacity = 0.f;
    // for (uniform int i = 0; self->lights && i < self->numLights; ++i)
    {
        const uniform Light* uniform light = self->lights[i];
        const varying vec2f s = make_vec2f(1.f / self->randomNumber);
        DifferentialGeometry dg;
        dg.P = point;
        const varying Light_SampleRes lightSample = light->sample(light, dg, s);

        vec3f dir;
        if (self->softShadows > 0.f)
            dir =
                normalize(self->softShadows *
                          getRandomVector(self->super.fb->size.x, sample,
                                          lightSample.dir, self->randomNumber));
        else
            dir = lightSample.dir;

        const float samplesPerPixel = self->volumeSamplesPerRay;
        const float epsilon = self->volumeDimensions.z / samplesPerPixel;

        for (float t = epsilon;
             pathOpacity < 1.f && t < self->volumeDimensions.z; t += epsilon)
        {
            const vec3f p = point + t * dir;
            const vec4f voxelColor = getVoxelColor(self, p);
            pathOpacity += (voxelColor.w > 0.f ? 1.f : 0.f);
        }
    }
    return pathOpacity;
}

inline float getEpsilon(const uniform VoxelizerRenderer* uniform self,
                        const float dist, const unsigned int iteration)
{
    return max(0.001f,
               dist / (self->volumeSamplesPerRay + 16 * min(iteration, 10)));
}

inline vec3f VoxelizerRenderer_shadeRay(
    const uniform VoxelizerRenderer* uniform self, varying ScreenSample& sample)
{
    vec4f pathColor = make_vec4f(0.f);
    float pathOpacity = 0.f;

    float t0, t1;
    vec3f aabbmin = make_vec3f(0, 0, 0);
    vec3f aabbmax = self->volumeDimensions;
    intersectBox(sample.ray, aabbmin, aabbmax, t0, t1);

    const float epsilon = getEpsilon(self, t1 - t0, sample.sampleID.z);
    const float random = getRandomValue(sample, self->randomNumber) * epsilon;
    t0 -= random;
    t1 -= random;

    float t = t0;
    vec3f point;
    for (t = t0; pathOpacity < 1.f && t < t1; t += epsilon)
    {
        point = (sample.ray.org + t * sample.ray.dir) - 0.5f;
        vec4f voxelColor = getVoxelColor(self, point);
        const bool hit = (voxelColor.w > 0.f);
        pathOpacity += voxelColor.w;
        composite(voxelColor, pathColor, 1.f);
        if (hit)
            break;
    }

    // Shadow
    if (pathOpacity > 0.5f && self->shadows > 0.f)
    {
        const float shadowContribution =
            pathOpacity *
            (1.f - self->shadows * getShadowContribution(self, sample, point));
        pathColor.x *= shadowContribution;
        pathColor.y *= shadowContribution;
        pathColor.z *= shadowContribution;
    }

    // Combine with background color
    const vec4f bgColor = make_vec4f(self->bgColor, 1.f);
    composite(bgColor, pathColor, 1.f);

    sample.alpha = pathOpacity;
    sample.z = t;

    return make_vec3f(pathColor);
}

void VoxelizerRenderer_renderSample(uniform Renderer* uniform _self,
                                    void* uniform perFrameData,
                                    varying ScreenSample& sample)
{
    uniform VoxelizerRenderer* uniform self =
        (uniform VoxelizerRenderer * uniform) _self;
    sample.ray.time = self->timestamp;
    sample.rgb = VoxelizerRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform VoxelizerRenderer_create(void* uniform cppE)
{
    uniform VoxelizerRenderer* uniform self =
        uniform new uniform VoxelizerRenderer;
    Renderer_Constructor(&self->super, cppE);
    self->super.renderSample = VoxelizerRenderer_renderSample;
    return self;
}

export void VoxelizerRenderer_set(
    void* uniform _self, const uniform vec3f& bgColor,
    const uniform float& shadows, const uniform float& softShadows,
    const uniform float& ambientOcclusionStrength,
    const uniform float& ambientOcclusionDistance,
    const uniform bool& shadingEnabled, const uniform int& randomNumber,
    const uniform float& timestamp, const uniform int& spp,
    const uniform bool& electronShadingEnabled, void** uniform lights,
    const uniform int32 numLights, void** uniform materials,
    const uniform int32 numMaterials, const uniform int32& volumeSamplesPerRay,
    uniform vec4f* uniform colormap,
    uniform vec3f* uniform emissionIntensitiesMap,
    const uniform int32 colorMapSize, const uniform float& colorMapMinValue,
    const uniform float& colorMapRange, const uniform float& threshold,
    const uniform float& divider, const uniform float& pixelOpacity)
{
    uniform VoxelizerRenderer* uniform self =
        (uniform VoxelizerRenderer * uniform) _self;

    self->bgColor = bgColor;
    self->shadows = shadows;
    self->softShadows = softShadows;
    self->ambientOcclusionStrength = ambientOcclusionStrength;
    self->ambientOcclusionDistance = ambientOcclusionDistance;
    self->shadingEnabled = shadingEnabled;
    self->randomNumber = randomNumber;
    self->timestamp = timestamp;
    self->spp = spp;
    self->electronShadingEnabled = electronShadingEnabled;

    self->lights = (const uniform Light* uniform* uniform)lights;
    self->numLights = numLights;

    self->materials =
        (const uniform ExtendedOBJMaterial* uniform* uniform)materials;
    self->numMaterials = numMaterials;

    self->colorMap = (uniform vec4f * uniform) colormap;
    self->emissionIntensitiesMap =
        (uniform vec3f * uniform) emissionIntensitiesMap;
    self->colorMapSize = colorMapSize;
    self->colorMapMinValue = colorMapMinValue;
    self->colorMapRange = colorMapRange;

    self->threshold = threshold;

    self->volumeSamplesPerRay = volumeSamplesPerRay;
    self->volumeDimensions = make_vec3f(1.f);

    self->divider = divider;
    self->pixelOpacity = pixelOpacity;
}
