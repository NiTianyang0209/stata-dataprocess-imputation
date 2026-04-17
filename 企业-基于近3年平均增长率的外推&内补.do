**# 最近3年均值填补
* 待处理变量为GG KK
*================================================================
* 变量缺失值填补：用距缺失年份最近的3年均值填补
* 面板结构：stkid（企业）、year（年份）
* 目标变量：GG KK
*
* 规则：
*   - 以缺失年份为中心，向两侧同步扩展搜索距离
*   - 每个距离 d，先检查 year-d，再检查 year+d
*   - 收集到3个有效值即停止（不足3个则用实际有效数量）
*   - 仅使用原始非缺失值，不使用已填补的值
*================================================================

sort stkid year

* 创建填补副本，保留原始变量不变
foreach var of varlist GG KK {
    clonevar `var'_imp = `var'
    label var `var'_imp "`var'（已填补）"
}

*================================================================
* 确定最大搜索距离（用年份跨度作为上界即可）
*================================================================
qui sum year
local max_dist = r(max) - r(min)

*================================================================
* 核心循环：逐企业 × 逐变量 × 逐缺失年份
*================================================================
qui levelsof stkid, local(id_list)

foreach id of local id_list {
    foreach var of varlist GG KK {

        * 获取该企业-变量的缺失年份
        qui levelsof year if stkid == `id' & missing(`var'), local(miss_yrs)

        * 若无缺失值则跳过
        if "`miss_yrs'" == "" {
            continue
        }

        foreach yr of local miss_yrs {

            * 初始化累加器
            local csum = 0
            local cn   = 0
            local done = 0

            * 从距离 d=1 开始向两侧扩展搜索
            forval d = 1/`max_dist' {

                * 已收集到3个则退出循环
                if `done' == 1 {
                    continue, break
                }

                * ── 检查前方第 d 年（year - d）──────────────────────
                qui sum `var' if stkid == `id' & year == `yr' - `d' & !missing(`var')
                if r(N) > 0 & `cn' < 3 {
                    local csum = `csum' + r(mean)
                    local cn   = `cn'   + 1
                }

                * ── 检查后方第 d 年（year + d）──────────────────────
                if `cn' < 3 {
                    qui sum `var' if stkid == `id' & year == `yr' + `d' & !missing(`var')
                    if r(N) > 0 {
                        local csum = `csum' + r(mean)
                        local cn   = `cn'   + 1
                    }
                }

                * 达到3个时标记退出
                if `cn' >= 3 {
                    local done = 1
                }
            }

            * 有效值数量 > 0 才填补
            if `cn' > 0 {
                local fill_val = `csum' / `cn'
                qui replace `var'_imp = `fill_val' ///
                    if stkid == `id' & year == `yr' & missing(`var'_imp)
            }

        }   // end foreach yr
    }       // end foreach var
}           // end foreach id

di as result ">>> 填补完成，新变量：GG_imp  KK_imp"
