const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const axios = require("axios");
const xml2js = require("xml2js");

admin.initializeApp();

// ============================================================
// 📊 СИНХРОНІЗАЦІЯ ПРИ ЗМІНІ ДОКУМЕНТА (існуюча функція)
// ============================================================
exports.onReportUpdateSync = onDocumentUpdated("users/{userId}/reports/{reportId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();
    const reportRef = event.data.after.ref;
    const userId = event.params.userId;

    if (newData.isSyncRequired === true && previousData.isSyncRequired === false) {
        console.log(`🚀 Початок синхронізації: ${newData.name}`);
        await syncReport(reportRef, userId, newData);
    }
    return null;
});

// ============================================================
// ⏰ SCHEDULED SYNC: ВІДКРИТТЯ РИНКУ (9:30 AM ET = 14:30 UTC)
// ============================================================
exports.scheduledSyncMarketOpen = onSchedule({
    schedule: "30 14 * * 1-5", // Пн-Пт о 14:30 UTC
    timeZone: "UTC",
    retryCount: 3,
}, async (event) => {
    console.log("🌅 Scheduled Sync: Ринок відкривається!");
    await runScheduledSync("market_open");
});

// ============================================================
// ⏰ SCHEDULED SYNC: ЗАКРИТТЯ РИНКУ (4:00 PM ET = 21:00 UTC)
// ============================================================
exports.scheduledSyncMarketClose = onSchedule({
    schedule: "0 21 * * 1-5", // Пн-Пт о 21:00 UTC
    timeZone: "UTC",
    retryCount: 3,
}, async (event) => {
    console.log("🌙 Scheduled Sync: Ринок закривається!");
    await runScheduledSync("market_close");
});

// ============================================================
// 🔄 ГОЛОВНА ФУНКЦІЯ SCHEDULED SYNC
// ============================================================
async function runScheduledSync(syncType) {
    const db = admin.firestore();
    
    try {
        // Знаходимо всіх користувачів з увімкненою автосинхронізацією
        const usersSnapshot = await db.collection("users")
            .where("isAutoSyncEnabled", "==", true)
            .get();

        console.log(`📋 Знайдено ${usersSnapshot.size} користувачів з автосинхронізацією`);

        for (const userDoc of usersSnapshot.docs) {
            const userData = userDoc.data();
            const userId = userDoc.id;

            // Перевіряємо чи цей тип синхронізації увімкнений
            if (syncType === "market_open" && !userData.syncOnMarketOpen) {
                console.log(`⏭️ Користувач ${userId}: пропускаємо market_open`);
                continue;
            }
            if (syncType === "market_close" && !userData.syncOnMarketClose) {
                console.log(`⏭️ Користувач ${userId}: пропускаємо market_close`);
                continue;
            }

            // Перевіряємо чи є токен
            if (!userData.ibkrToken) {
                console.log(`⚠️ Користувач ${userId}: немає IBKR токена`);
                continue;
            }

            // Отримуємо всі звіти користувача
            const reportsSnapshot = await db.collection("users")
                .doc(userId)
                .collection("reports")
                .get();

            console.log(`📊 Користувач ${userId}: ${reportsSnapshot.size} звітів`);

            // Запускаємо синхронізацію для кожного звіту
            for (const reportDoc of reportsSnapshot.docs) {
                const reportData = reportDoc.data();
                
                // Пропускаємо якщо вже синхронізується
                if (reportData.isSyncRequired) {
                    console.log(`⏳ Звіт ${reportDoc.id} вже синхронізується`);
                    continue;
                }

                console.log(`🔄 Запускаємо синхронізацію звіту: ${reportData.name}`);
                
                // Ставимо прапорець синхронізації
                await reportDoc.ref.update({
                    isSyncRequired: true,
                    scheduledSyncType: syncType,
                    lastError: null
                });
            }
        }

        console.log(`✅ Scheduled sync (${syncType}) завершено`);

    } catch (error) {
        console.error(`🛑 Помилка scheduled sync: ${error.message}`);
        throw error;
    }
}

// ============================================================
// 📥 ФУНКЦІЯ СИНХРОНІЗАЦІЇ ЗВІТУ
// ============================================================
async function syncReport(reportRef, userId, reportData) {
    try {
        // Отримуємо токен користувача
        const userDoc = await admin.firestore().doc(`users/${userId}`).get();
        const userData = userDoc.data() || {};
        const ibkrToken = userData.ibkrToken;
        const queryId = reportData.queryId || userData.queryId;

        if (!ibkrToken || !queryId) {
            throw new Error("Немає токена або ID звіту.");
        }

        // 1. Запит до IBKR
        const sendReqUrl = `https://www.interactivebrokers.com/Universal/servlet/FlexStatementService.SendRequest?t=${ibkrToken}&q=${queryId}&v=3`;
        
        const reqRes = await axios.get(sendReqUrl);
        const parser = new xml2js.Parser();
        const parsedReq = await parser.parseStringPromise(reqRes.data);

        if (!parsedReq.FlexStatementResponse || parsedReq.FlexStatementResponse.Status[0] !== "Success") {
            const errorMsg = parsedReq.FlexStatementResponse?.ErrorMessage?.[0] || "Помилка API IBKR";
            throw new Error(errorMsg);
        }

        const referenceCode = parsedReq.FlexStatementResponse.ReferenceCode[0];
        let baseUrl = parsedReq.FlexStatementResponse.Url[0];

        // Підміна неробочого домену
        if (baseUrl.includes("gdcdyn.interactivebrokers.com")) {
            baseUrl = baseUrl.replace("gdcdyn.interactivebrokers.com", "www.interactivebrokers.com");
        }

        console.log(`⏳ Чекаємо генерації звіту...`);

        // 2. Очікування та отримання звіту
        let reportResponse = null;
        for (let i = 0; i < 30; i++) {
            await new Promise(resolve => setTimeout(resolve, 3000));
            
            const response = await axios.get(`${baseUrl}?t=${ibkrToken}&q=${referenceCode}&v=3`);
            
            if (response.data.includes("Statement is being generated") || response.data.includes("Fail")) {
                console.log(`⏳ Спроба ${i + 1}/30...`);
                continue;
            }
            
            reportResponse = response;
            break;
        }

        if (!reportResponse) {
            throw new Error("Тайм-аут: Звіт генерувався занадто довго.");
        }

        const parsedReport = await parser.parseStringPromise(reportResponse.data);

        if (!parsedReport.FlexQueryResponse || !parsedReport.FlexQueryResponse.FlexStatements) {
            throw new Error("Отримано порожній XML.");
        }

        const statement = parsedReport.FlexQueryResponse.FlexStatements[0].FlexStatement[0];

        // 3. Парсинг даних
        const parsedData = parseIBKRStatement(statement);

        // 4. Запис у базу
        await reportRef.update({
            ...parsedData,
            isSyncRequired: false,
            lastSyncTime: admin.firestore.FieldValue.serverTimestamp(),
            lastError: null
        });

        // 5. Оновлюємо статус синхронізації користувача
        await admin.firestore().doc(`users/${userId}`).update({
            lastSyncTime: admin.firestore.FieldValue.serverTimestamp(),
            lastSyncStatus: "success"
        });

        // 6. Перевіряємо нові дивіденди
        const previousDividends = reportData.dividends || [];
        const newDividends = findNewDividends(previousDividends, parsedData.dividends);
        
        if (newDividends.length > 0) {
            await sendDividendNotification(userId, newDividends);
        }

        // 7. Надсилаємо push-сповіщення про синхронізацію
        await sendSyncNotification(userId, reportData.name, parsedData.lastBalance);

        console.log(`✅ Успіх! Баланс: ${parsedData.lastBalance}, Кеш: ${parsedData.cashBalance}`);

    } catch (error) {
        console.error("🛑 Помилка:", error.message);
        
        await reportRef.update({ 
            isSyncRequired: false,
            lastError: error.message 
        });

        // Оновлюємо статус помилки
        await admin.firestore().doc(`users/${userId}`).update({
            lastSyncTime: admin.firestore.FieldValue.serverTimestamp(),
            lastSyncStatus: "error",
            lastError: error.message
        });
    }
}

// ============================================================
// 📊 ПАРСИНГ IBKR STATEMENT
// ============================================================
function parseIBKRStatement(statement) {
    let netValue = 0;
    let cashBalance = 0;

    // 1. Загальний баланс (NAV)
    if (statement.EquitySummaryByReportDateInBase && statement.EquitySummaryByReportDateInBase[0].EquitySummaryByReportDateInBase) {
        const navSection = statement.EquitySummaryByReportDateInBase[0].EquitySummaryByReportDateInBase[0].$;
        netValue = parseFloat(navSection.total || navSection.cash || "0"); 
        if (netValue === 0) {
            netValue = parseFloat(navSection.cash || "0") + parseFloat(navSection.stock || "0");
        }
    } else if (statement.AccountInformation && statement.AccountInformation[0]) {
        netValue = parseFloat(statement.AccountInformation[0].$.netLiquidity || statement.AccountInformation[0].$.netAssetValue || "0");
    }

    // 2. Кеш
    if (statement.CashReport && statement.CashReport[0].CashReportCurrency) {
        const cashData = statement.CashReport[0].CashReportCurrency.find(c => c.$.currency === 'USD' || c.$.currency === 'BASE') || statement.CashReport[0].CashReportCurrency[0];
        if (cashData) {
            const info = cashData.$;
            cashBalance = parseFloat(info.endingSettled || info.endingCash || info.total || "0");
        }
    } else if (statement.AccountInformation && statement.AccountInformation[0]) {
        const info = statement.AccountInformation[0].$;
        cashBalance = parseFloat(info.settledCash || info.totalCashBalance || "0");
    }

    // 3. Активи
    let assets = [];
    if (statement.OpenPositions && statement.OpenPositions[0].OpenPosition) {
        assets = statement.OpenPositions[0].OpenPosition.map(pos => ({
            symbol: pos.$.symbol || "Unknown",
            quantity: parseFloat(pos.$.position || "0"),
            value: parseFloat(pos.$.positionValue || "0"),
            change: parseFloat(pos.$.unrealizedPnl || "0"),
            name: pos.$.description || pos.$.symbol || "N/A"
        }));
    }

    // 4. Дивіденди
    let dividends = [];
    let totalDividends = 0;
    
    if (statement.ChangeInDividendAccruals && statement.ChangeInDividendAccruals[0].ChangeInDividendAccrual) {
        dividends = statement.ChangeInDividendAccruals[0].ChangeInDividendAccrual.map(div => {
            const amount = parseFloat(div.$.grossAmount || div.$.netAmount || "0");
            totalDividends += amount;
            return {
                date: div.$.payDate || div.$.date || "",
                symbol: div.$.symbol || "DIV",
                amount: amount,
                description: div.$.description || "Dividend"
            };
        });
    } else if (statement.CashTransactions && statement.CashTransactions[0].CashTransaction) {
        dividends = statement.CashTransactions[0].CashTransaction
            .filter(tx => tx.$.type === "Dividends")
            .map(tx => {
                const amount = parseFloat(tx.$.amount || "0");
                totalDividends += amount;
                return {
                    date: tx.$.dateTime || "",
                    symbol: tx.$.symbol || "CASH",
                    amount: amount,
                    description: tx.$.description || ""
                };
            });
    }

    // 5. Торги
    let trades = [];
    let totalCommissions = 0;
    if (statement.Trades && statement.Trades[0].Trade) {
        trades = statement.Trades[0].Trade.map(trade => {
            const commission = Math.abs(parseFloat(trade.$.ibCommission || trade.$.commission || "0"));
            totalCommissions += commission;
            return {
                date: trade.$.dateTime || "",
                symbol: trade.$.symbol || "Unknown",
                action: trade.$.buySell || "",
                quantity: parseFloat(trade.$.quantity || "0"),
                price: parseFloat(trade.$.tradePrice || "0"),
                cost: parseFloat(trade.$.cost || "0"),
                commission: commission
            };
        });
    }

    // 6. Депозити та зняття
    let totalDeposits = 0;
    let totalWithdrawals = 0;
    let cashTransactions = [];

    if (statement.CashTransactions && statement.CashTransactions[0].CashTransaction) {
        statement.CashTransactions[0].CashTransaction.forEach(tx => {
            const type = tx.$.type || "";
            const amount = parseFloat(tx.$.amount || "0");
            
            cashTransactions.push({
                date: tx.$.dateTime || "",
                type: type,
                amount: amount,
                description: tx.$.description || "",
                symbol: tx.$.symbol || ""
            });

            if (type === "Deposits" || type === "Deposit") {
                totalDeposits += Math.abs(amount);
            } else if (type === "Withdrawals" || type === "Withdrawal") {
                totalWithdrawals += Math.abs(amount);
            }
        });
    }

    return {
        lastBalance: netValue,
        value: netValue,
        cashBalance: cashBalance,
        assets: assets,
        dividends: dividends,
        totalDividends: totalDividends,
        trades: trades,
        totalCommissions: totalCommissions,
        totalDeposits: totalDeposits,
        totalWithdrawals: totalWithdrawals,
        cashTransactions: cashTransactions
    };
}

// ============================================================
// 💰 ПОШУК НОВИХ ДИВІДЕНДІВ
// ============================================================
function findNewDividends(previousDividends, currentDividends) {
    if (!currentDividends || currentDividends.length === 0) {
        return [];
    }
    
    // Створюємо Set з унікальними ключами попередніх дивідендів
    const previousKeys = new Set(
        previousDividends.map(d => `${d.symbol}_${d.date}_${d.amount}`)
    );
    
    // Знаходимо нові дивіденди
    const newDividends = currentDividends.filter(d => {
        const key = `${d.symbol}_${d.date}_${d.amount}`;
        return !previousKeys.has(key);
    });
    
    return newDividends;
}

// ============================================================
// 💵 PUSH NOTIFICATION: ДИВІДЕНДИ
// ============================================================
async function sendDividendNotification(userId, newDividends) {
    try {
        const userDoc = await admin.firestore().doc(`users/${userId}`).get();
        const userData = userDoc.data() || {};
        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
            console.log(`⚠️ Користувач ${userId} не має FCM токена для дивідендів`);
            return;
        }

        // Рахуємо загальну суму нових дивідендів
        const totalAmount = newDividends.reduce((sum, d) => sum + d.amount, 0);
        
        // Групуємо по символах
        const symbols = [...new Set(newDividends.map(d => d.symbol))];
        const symbolsText = symbols.length <= 3 
            ? symbols.join(', ') 
            : `${symbols.slice(0, 3).join(', ')} та ще ${symbols.length - 3}`;

        let title, body;

        if (newDividends.length === 1) {
            const div = newDividends[0];
            title = `💰 Дивіденд від ${div.symbol}!`;
            body = `Ви отримали $${div.amount.toFixed(2)}`;
        } else {
            title = `💰 ${newDividends.length} нових дивідендів!`;
            body = `${symbolsText}: загалом $${totalAmount.toFixed(2)}`;
        }

        const message = {
            notification: {
                title: title,
                body: body
            },
            data: {
                type: "dividend",
                count: newDividends.length.toString(),
                totalAmount: totalAmount.toString(),
                symbols: symbols.join(',')
            },
            android: {
                notification: {
                    channelId: "dividends_channel",
                    priority: "high",
                    icon: "ic_money"
                }
            },
            apns: {
                payload: {
                    aps: {
                        badge: newDividends.length,
                        sound: "default"
                    }
                }
            },
            token: fcmToken
        };

        await admin.messaging().send(message);
        console.log(`💵 Dividend push надіслано: ${newDividends.length} дивідендів на $${totalAmount.toFixed(2)}`);

        // Зберігаємо історію сповіщень
        await admin.firestore()
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add({
                type: 'dividend',
                title: title,
                body: body,
                dividends: newDividends,
                totalAmount: totalAmount,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                read: false
            });

    } catch (error) {
        console.error(`⚠️ Помилка надсилання dividend push: ${error.message}`);
    }
}

// ============================================================
// 📱 PUSH NOTIFICATION: СИНХРОНІЗАЦІЯ
// ============================================================
async function sendSyncNotification(userId, reportName, balance) {
    try {
        const userDoc = await admin.firestore().doc(`users/${userId}`).get();
        const fcmToken = userDoc.data()?.fcmToken;

        if (!fcmToken) {
            console.log(`⚠️ Користувач ${userId} не має FCM токена`);
            return;
        }

        const message = {
            notification: {
                title: "📊 Звіт оновлено!",
                body: `${reportName}: $${balance.toFixed(2)}`
            },
            data: {
                type: "sync_complete",
                reportName: reportName,
                balance: balance.toString()
            },
            token: fcmToken
        };

        await admin.messaging().send(message);
        console.log(`📱 Push надіслано користувачу ${userId}`);

    } catch (error) {
        console.error(`⚠️ Помилка надсилання push: ${error.message}`);
    }
}
