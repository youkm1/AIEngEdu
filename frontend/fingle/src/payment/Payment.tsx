import { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import apiService from '../services/api';
import { useAuth } from '../contexts/AuthContext';

const Payment = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [isProcessing, setIsProcessing] = useState(false);
  
  // Get payment info from navigation state
  const { orderId, amount, orderName, membershipType, userId } = location.state || {};

  useEffect(() => {
    // Redirect if no payment info
    if (!orderId || !amount || !membershipType || !userId) {
      navigate('/');
    }
  }, [orderId, amount, membershipType, userId, navigate]);

  const handlePayment = async () => {
    if (!user) {
      alert('Please login to continue');
      navigate('/');
      return;
    }

    setIsProcessing(true);
    
    try {
      // Mock payment key for testing
      const mockPaymentKey = `payment_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
      
      // Confirm payment with backend
      const response = await apiService.confirmPayment(
        userId,
        mockPaymentKey,
        orderId,
        amount
      );

      if (response.success) {
        alert(`Payment successful! Your ${membershipType} membership is now active.`);
        navigate('/');
      } else {
        alert('Payment failed. Please try again.');
      }
    } catch (error) {
      console.error('Payment error:', error);
      alert('Payment processing failed. Please try again.');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleCancel = () => {
    navigate('/');
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center px-4">
      <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-8">
        <h2 className="text-2xl font-bold text-center mb-6">Payment Checkout</h2>
        
        <div className="space-y-4 mb-6">
          <div className="border-b pb-4">
            <p className="text-sm text-gray-600">Order Details</p>
            <p className="text-lg font-semibold">{orderName}</p>
          </div>
          
          <div className="border-b pb-4">
            <p className="text-sm text-gray-600">Membership Type</p>
            <p className="text-lg font-semibold capitalize">{membershipType}</p>
          </div>
          
          <div className="border-b pb-4">
            <p className="text-sm text-gray-600">Amount</p>
            <p className="text-2xl font-bold text-blue-600">₩{amount?.toLocaleString()}</p>
          </div>
        </div>

        <div className="bg-yellow-50 border border-yellow-200 rounded-md p-4 mb-6">
          <p className="text-sm text-yellow-800">
            <strong>Test Mode:</strong> This is a mock payment system. Click "Confirm Payment" to simulate a successful payment.
          </p>
        </div>

        <div className="space-y-3">
          <button
            onClick={handlePayment}
            disabled={isProcessing}
            className={`w-full py-3 px-4 rounded-md font-semibold text-white transition-colors ${
              isProcessing 
                ? 'bg-gray-400 cursor-not-allowed' 
                : 'bg-blue-600 hover:bg-blue-700'
            }`}
          >
            {isProcessing ? 'Processing...' : 'Confirm Payment'}
          </button>
          
          <button
            onClick={handleCancel}
            disabled={isProcessing}
            className="w-full py-3 px-4 rounded-md font-semibold text-gray-700 bg-gray-200 hover:bg-gray-300 transition-colors"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
};

export default Payment;