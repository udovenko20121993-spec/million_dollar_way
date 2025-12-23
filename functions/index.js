const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const axios = require("axios");
const xml2js = require("xml2js");

admin.initializeApp();

exports.onReportUpdateSync = onDocumentUpdated("users/{userId}/reports/{reportId}", async (event) => {
    const newData = event.data.after.data();
    const previousData = event.data.before.data();
    const reportRef = event.data.after.ref;

    if (newData.isSyncRequired === true && previousData.isSyncRequired === false) {
        console.log(`🚀 Початок синхронізації: ${newData.name}`);

        try {
            const userDoc = await admin.firestore().doc(`users/${event.params.userId}`).get();
            const ibkrToken = userDoc.data()?.ibkrToken;
            const queryId = newData.queryId;

            if (!ibkrToken || !queryId) throw new Error("Немає токена або ID звіту.");

            // 1. Запит до банку
            const sendReqUrl = `https://www.interactivebrokers.com/Universal/servlet/FlexStatementService.SendRequest?t=${ibkrToken}&q=${queryId}&v=3`;
            
            const reqRes = await axios.get(sendReqUrl);
            const parser = new xml2js.Parser();
            const parsedReq = await parser.parseStringPromise(reqRes.data);

            if (!parsedReq.FlexStatementResponse || parsedReq.FlexStatementResponse.Status[0] !== "Success") {
                const errorMsg = parsedReq.FlexStatementResponse?.ErrorMessage?.[0] || "Помилка API IBKR";
                throw new Error(errorMsg);
            }

            const referenceCode = parsedReq.FlexStatementResponse.ReferenceCode[0];
            const baseUrl = parsedReq.FlexStatementResponse.Url[0];

            console.log(`⏳ Чекаємо генерації звіту...`);
            await new Promise(resolve => setTimeout(resolve, 10000)); 

            // 2. Отримання звіту
            const reportRes = await axios.get(`${baseUrl}?t=${ibkrToken}&q=${referenceCode}&v=3`);
            const parsedReport = await parser.parseStringPromise(reportRes.data);

            if (!parsedReport.FlexQueryResponse || !parsedReport.FlexQueryResponse.FlexStatements) {
                throw new Error("Отримано порожній XML.");
            }

            const statement = parsedReport.FlexQueryResponse.FlexStatements[0].FlexStatement[0];

            // --- ПАРСИНГ ДАНИХ (ОНОВЛЕНО) ---

            let netValue = 0;
            let cashBalance = 0;

            // 1. ШУКАЄМО ЗАГАЛЬНИЙ БАЛАНС (NAV)
            // Пріоритет: NAV in Base -> Account Info
            if (statement.EquitySummaryByReportDateInBase && statement.EquitySummaryByReportDateInBase[0].EquitySummaryByReportDateInBase) {
                // Нова секція NAV
                const navSection = statement.EquitySummaryByReportDateInBase[0].EquitySummaryByReportDateInBase[0].$;
                netValue = parseFloat(navSection.total || navSection.cash || "0"); 
                // Якщо total немає, спробуємо скласти cash + stock
                if (netValue === 0) {
                     netValue = parseFloat(navSection.cash || "0") + parseFloat(navSection.stock || "0");
                }
            } else if (statement.AccountInformation && statement.AccountInformation[0]) {
                // Стара секція (резерв)
                netValue = parseFloat(statement.AccountInformation[0].$.netLiquidity || statement.AccountInformation[0].$.netAssetValue || "0");
            }

            // 2. ШУКАЄМО КЕШ (Cash Report) - ТУТ ВАШІ 0.60$
            if (statement.CashReport && statement.CashReport[0].CashReportCurrency) {
                // IBKR дає кеш по валютах. Шукаємо USD або Base.
                const cashData = statement.CashReport[0].CashReportCurrency.find(c => c.$.currency === 'USD' || c.$.currency === 'BASE') || statement.CashReport[0].CashReportCurrency[0];
                
                if (cashData) {
                    const info = cashData.$;
                    // Шукаємо endingSettled (найточніше) або endingCash
                    cashBalance = parseFloat(info.endingSettled || info.endingCash || info.total || "0");
                }
            } else if (statement.AccountInformation && statement.AccountInformation[0]) {
                // Резервний пошук
                const info = statement.AccountInformation[0].$;
                cashBalance = parseFloat(info.settledCash || info.totalCashBalance || "0");
            }

            // 3. АКТИВИ
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

            // 4. ДИВІДЕНДИ
            let dividends = [];
            let totalDividends = 0;
            
            // Перевіряємо ChangeInDividendAccruals або CashTransactions
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

            // 5. ТОРГИ
            let trades = [];
            if (statement.Trades && statement.Trades[0].Trade) {
                trades = statement.Trades[0].Trade.map(trade => ({
                    date: trade.$.dateTime || "",
                    symbol: trade.$.symbol || "Unknown",
                    action: trade.$.buySell || "",
                    quantity: parseFloat(trade.$.quantity || "0"),
                    price: parseFloat(trade.$.tradePrice || "0"),
                    cost: parseFloat(trade.$.cost || "0")
                }));
            }

            // --- ЗАПИС У БАЗУ ---
            const batch = admin.firestore().batch();
            
            batch.update(reportRef, {
                lastBalance: netValue,
                value: netValue,
                cashBalance: cashBalance, // Тут будуть 0.60
                assets: assets,
                dividends: dividends,
                totalDividends: totalDividends,
                trades: trades,
                isSyncRequired: false,
                lastSyncTime: admin.firestore.FieldValue.serverTimestamp(),
                lastError: null
            });

            await batch.commit();
            console.log(`✅ Успіх! Баланс: ${netValue}, Кеш: ${cashBalance}`);

        } catch (error) {
            console.error("🛑 Помилка:", error.message);
            await reportRef.update({ 
                isSyncRequired: false,
                lastError: error.message 
            });
        }
    }
    return null;
});