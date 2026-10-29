package com.digitalguide.common;

public final class UserContext {

    private static final ThreadLocal<Long> HOLDER = new ThreadLocal<>();

    private UserContext() {
    }

    public static void set(Long userId) {
        HOLDER.set(userId);
    }

    public static Long get() {
        return HOLDER.get();
    }

    public static Long require() {
        Long userId = HOLDER.get();
        if (userId == null) {
            throw new BizException(401, "未登录");
        }
        return userId;
    }

    public static void clear() {
        HOLDER.remove();
    }
}
