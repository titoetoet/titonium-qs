pragma Singleton

import QtQuick

QtObject {
    id: root

    // Timezone offset for Vietnam (UTC+7)
    readonly property real timeZone: 7.0

    readonly property var canNames: ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
    readonly property var chiNames: ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]

    function jdFromDate(dd, mm, yy) {
        const a = Math.floor((14 - mm) / 12);
        const y = yy + 4800 - a;
        const m = mm + 12 * a - 3;
        return dd + Math.floor((153 * m + 2) / 5) + 365 * y + Math.floor(y / 4) - Math.floor(y / 100) + Math.floor(y / 400) - 32045;
    }

    function getNewMoonDay(k, tz) {
        const T = k / 1236.85;
        const T2 = T * T;
        const T3 = T2 * T;
        const dr = Math.PI / 180;
        let Jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3;
        Jd1 += 0.00033 * Math.sin((166.56 + 132.87 * T - 0.009173 * T2) * dr);
        const M = 359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3;
        const Mpr = 306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3;
        const F = 21.2964 + 390.67050646 * k - 0.0016528 * T2 - 0.00000239 * T3;
        let C1 = (0.1734 - 0.000393 * T) * Math.sin(M * dr) + 0.0021 * Math.sin(2 * dr * M);
        C1 -= 0.4068 * Math.sin(Mpr * dr) + 0.0161 * Math.sin(2 * dr * Mpr);
        C1 -= 0.0004 * Math.sin(3 * dr * Mpr);
        C1 += 0.0104 * Math.sin(2 * dr * F) - 0.0051 * Math.sin((M + Mpr) * dr);
        C1 -= 0.0074 * Math.sin((M - Mpr) * dr) + 0.0004 * Math.sin((2 * F + M) * dr);
        C1 -= 0.0004 * Math.sin((2 * F - M) * dr) - 0.0006 * Math.sin((2 * F + Mpr) * dr);
        C1 += 0.0010 * Math.sin((2 * F - Mpr) * dr) + 0.0005 * Math.sin((2 * Mpr + M) * dr);
        const deltat = (T < -11) ? (0.96 + 0.5 * T) : ((T < 0) ? (0.5 + 0.2 * T) : 0);
        const JdNew = Jd1 + C1 - deltat;
        return Math.floor(JdNew + 0.5 + tz / 24);
    }

    function getSunLongitude(jdn, tz) {
        const T = (jdn - 2451545.0 + 0.5 - tz / 24) / 36525;
        const T2 = T * T;
        const dr = Math.PI / 180;
        const M = 357.52910 + 35999.05029 * T - 0.0001537 * T2;
        const L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2;
        let DL = (1.914602 - 0.004817 * T - 0.000014 * T2) * Math.sin(M * dr);
        DL += (0.019993 - 0.000101 * T) * Math.sin(2 * M * dr) + 0.000289 * Math.sin(3 * M * dr);
        let L = L0 + DL;
        L = L * dr;
        L = L - Math.PI * 2 * Math.floor(L / (Math.PI * 2));
        return Math.floor(L / (Math.PI / 6));
    }

    function getLunarMonth11(yy, tz) {
        const off = jdFromDate(31, 12, yy) - 2415021;
        const k = Math.floor(off / 29.530588853);
        let nm = getNewMoonDay(k, tz);
        const sunLong = getSunLongitude(nm, tz);
        if (sunLong >= 9) {
            nm = getNewMoonDay(k - 1, tz);
        }
        return nm;
    }

    function getLeapMonthOffset(a11, tz) {
        const k = Math.floor((a11 - 2415021.07699) / 29.530588853 + 0.5);
        let last = 0;
        let i = 1;
        let arc = getSunLongitude(getNewMoonDay(k + i, tz), tz);
        do {
            last = arc;
            i++;
            arc = getSunLongitude(getNewMoonDay(k + i, tz), tz);
        } while (arc !== last && i < 14);
        return i - 1;
    }

    function convertSolar2Lunar(dd, mm, yy) {
        const tz = root.timeZone;
        const dayNumber = jdFromDate(dd, mm, yy);
        const k = Math.floor((dayNumber - 2415021.07699) / 29.530588853);
        let monthStart = getNewMoonDay(k + 1, tz);
        if (monthStart > dayNumber) {
            monthStart = getNewMoonDay(k, tz);
        }
        let a11 = getLunarMonth11(yy, tz);
        let b11 = a11;
        let lunarYear = yy;
        if (a11 >= monthStart) {
            lunarYear = yy - 1;
            a11 = getLunarMonth11(yy - 1, tz);
        } else {
            b11 = getLunarMonth11(yy + 1, tz);
        }
        const lunarDay = dayNumber - monthStart + 1;
        const diff = Math.floor((monthStart - a11) / 29);
        let lunarLeap = 0;
        let lunarMonth = diff + 11;
        if (b11 - a11 > 365) {
            const leapMonthDiff = getLeapMonthOffset(a11, tz);
            if (diff >= leapMonthDiff) {
                lunarMonth = diff + 10;
                if (diff === leapMonthDiff) {
                    lunarLeap = 1;
                }
            }
        }
        if (lunarMonth > 12) {
            lunarMonth = lunarMonth - 12;
        }
        if (lunarMonth >= 11 && diff < 4) {
            lunarYear -= 1;
        }

        const isSpecial = (lunarDay === 1 || lunarDay === 15);
        const displayText = (lunarDay === 1) ? (lunarDay + "/" + lunarMonth) : ("" + lunarDay);
        const yearCan = root.canNames[(lunarYear + 6) % 10];
        const yearChi = root.chiNames[(lunarYear + 8) % 12];
        const yearName = yearCan + " " + yearChi;

        return {
            day: lunarDay,
            month: lunarMonth,
            year: lunarYear,
            yearName: yearName,
            isLeap: (lunarLeap === 1),
            isSpecial: isSpecial,
            displayText: displayText
        };
    }

    readonly property var generalQuotes: [
        {
            vi: "Tâm tịnh như nước hồ thu, việc đời dẫu gấp tâm thường thảnh thơi.",
            en: "Keep the mind as serene as autumn waters; remain at peace amidst the rush."
        },
        {
            vi: "Trăng có lúc tròn lúc khuyết, người có lúc hợp lúc tan. Vạn sự tùy duyên.",
            en: "The moon waxes and wanes; embrace life's flowing nature with ease."
        },
        {
            vi: "Nắng tốt dưa, mưa tốt lúa. Thuận theo tự nhiên, đời tự khắc an yên.",
            en: "Sun feeds the melon, rain nourishes the rice. Live in harmony with nature."
        },
        {
            vi: "Thời gian như bóng câu qua cửa, trân quý từng phút giây của hiện tại.",
            en: "Time passes like a fleeting shadow; cherish every moment in the present."
        },
        {
            vi: "Gieo hạt mầm thiện lương, ắt gặt hái hoa trái bình an và phước đức.",
            en: "Sow seeds of kindness today to harvest the fruits of peace tomorrow."
        },
        {
            vi: "Trời đất chuyển vần bốn mùa, lòng người giữ lấy sự kiên định và bao dung.",
            en: "As seasons turn through the heavens, keep the heart steadfast and compassionate."
        },
        {
            vi: "Biết đủ là phú quý, tâm an là hạnh phúc lớn nhất của đời người.",
            en: "Contentment is true wealth; a tranquil mind is the greatest joy."
        },
        {
            vi: "Mỗi ngày mới dưới ánh trăng và mặt trời đều mang theo một niềm hy vọng.",
            en: "Every dawn and moonrise brings a brand new beginning and renewed hope."
        },
        {
            vi: "Nước chảy đá mềm, nhẫn nại và kiên trì sẽ mở lối qua mọi chông gai.",
            en: "Water shapes the stone; patience and perseverance forge the way forward."
        },
        {
            vi: "Lắng nghe tiếng gió mùa sang, để tâm hồn nhẹ bước giữa dòng đời hối hả.",
            en: "Listen to the whispering seasonal breeze, letting the soul walk lightly."
        }
    ]

    function getDailyQuote(dd, mm, yy) {
        const lunar = convertSolar2Lunar(dd, mm, yy);

        // 1. Mùng Một (New Moon)
        if (lunar.day === 1) {
            return {
                vi: "Mùng một đầu tháng, khởi nguồn an lành, vạn sự hanh thông.",
                en: "A new moon begins: may serenity and prosperity guide your path."
            };
        }

        // 2. Ngày Rằm 15 (Full Moon)
        if (lunar.day === 15) {
            if (lunar.month === 7) {
                return {
                    vi: "Trăng rằm tháng Bảy Vu Lan, vẹn tròn hiếu nghĩa lắng lòng tri ân.",
                    en: "The seventh full moon: a sacred time for gratitude and filial love."
                };
            }
            if (lunar.month === 8) {
                return {
                    vi: "Trăng thu tròn vành vạnh, sum họp ấm áp trọn vẹn tình thân.",
                    en: "The mid-autumn moon shines bright, celebrating warmth and reunion."
                };
            }
            if (lunar.month === 1) {
                return {
                    vi: "Rằm tháng Giêng trăng sáng ngời, cầu cho muôn nhà phúc lộc bình an.",
                    en: "The first full moon of the year illuminates hope, blessings, and peace."
                };
            }
            return {
                vi: "Trăng tròn vằng vặc soi đêm vắng, tâm tịnh an nhiên vạn sự hòa.",
                en: "The full moon illuminates the night; a calm mind brings universal harmony."
            };
        }

        // 3. Ngày 30 / 29 (Cuối tháng Âm Lịch)
        if (lunar.day >= 29) {
            return {
                vi: "Khép lại một tuần trăng, thanh lọc tâm trí đón nhận những điều mới mẻ.",
                en: "Closing a lunar cycle: reflect with gratitude and welcome the new dawn."
            };
        }

        // 4. Deterministic daily quote from array based on day & month
        const index = (dd * 3 + lunar.day * 7 + lunar.month) % generalQuotes.length;
        return generalQuotes[index];
    }
}

