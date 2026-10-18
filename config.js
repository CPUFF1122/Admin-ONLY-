// แก้ค่าตรงนี้ให้เป็นของคุณ (ค่า key เป็น publishable/anon key เปิดเผยได้ ความปลอดภัยอยู่ที่ RLS ใน supabase.sql)
const CFG={
  url:'https://YOUR-PROJECT.supabase.co',
  key:'YOUR-ANON-PUBLIC-KEY',
  shop:'ชื่อร้าน',
  promptpay:'PromptPay 08x-xxx-xxxx ชื่อบัญชี',
  qr:'',                       // ใส่ path รูป QR เช่น 'qr.png' (วางไฟล์ไว้โฟลเดอร์เดียวกับ index.html)
  contact:'https://line.me/ti/p/~yourid'
};
